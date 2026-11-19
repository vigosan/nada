import AppKit
import NadaCore

enum RemoteSocket {
    static var path: String {
        ProcessInfo.processInfo.environment["NADA_SOCKET"]
            ?? URL.applicationSupportDirectory.appending(path: "Nada/nada.sock").path
    }

    static func open() -> Int32? {
        let descriptor = socket(AF_UNIX, SOCK_STREAM, 0)
        guard descriptor >= 0 else { return nil }
        var on: Int32 = 1
        setsockopt(descriptor, SOL_SOCKET, SO_NOSIGPIPE, &on, socklen_t(MemoryLayout<Int32>.size))
        return descriptor
    }

    static func with<Result>(_ path: String, _ body: (UnsafePointer<sockaddr>, socklen_t) -> Result) -> Result? {
        var address = sockaddr_un()
        address.sun_family = sa_family_t(AF_UNIX)
        let bytes = Array(path.utf8)
        let capacity = MemoryLayout.size(ofValue: address.sun_path)
        guard bytes.count < capacity else { return nil }
        withUnsafeMutableBytes(of: &address.sun_path) { $0.copyBytes(from: bytes) }
        return withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { body($0, socklen_t(MemoryLayout<sockaddr_un>.size)) }
        }
    }

    static func readLine(_ descriptor: Int32) -> Data {
        var line = Data()
        var buffer = [UInt8](repeating: 0, count: 65_536)
        while !line.contains(UInt8(ascii: "\n")) {
            let count = read(descriptor, &buffer, buffer.count)
            guard count > 0 else { break }
            line.append(buffer, count: count)
        }
        return line.prefix { $0 != UInt8(ascii: "\n") }
    }

    static func write(_ data: Data, to descriptor: Int32) {
        data.withUnsafeBytes { bytes in
            var sent = 0
            while sent < bytes.count {
                let count = Darwin.write(descriptor, bytes.baseAddress! + sent, bytes.count - sent)
                guard count > 0 else { return }
                sent += count
            }
        }
    }
}

final class RemoteServer {
    private let path = RemoteSocket.path
    private let answer: @MainActor (RemoteRequest) async -> RemoteResponse
    private var source: DispatchSourceRead?

    init?(answer: @escaping @MainActor (RemoteRequest) async -> RemoteResponse) {
        self.answer = answer
        try? FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        unlink(path)
        guard let descriptor = RemoteSocket.open() else { return nil }
        guard RemoteSocket.with(path, { bind(descriptor, $0, $1) }) == 0, chmod(path, 0o600) == 0, listen(descriptor, 8) == 0 else {
            NSLog("Control desde la terminal: no se puede escuchar en %@: %@", path, String(cString: strerror(errno)))
            close(descriptor)
            return nil
        }
        let source = DispatchSource.makeReadSource(fileDescriptor: descriptor, queue: .global(qos: .userInitiated))
        source.setEventHandler { [answer] in
            let connection = accept(descriptor, nil, nil)
            guard connection >= 0 else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                let request = try? RemoteRequest(line: RemoteSocket.readLine(connection))
                Task { @MainActor in
                    let response = if let request { await answer(request) } else { RemoteResponse(ok: false, output: "orden ilegible") }
                    DispatchQueue.global(qos: .userInitiated).async {
                        (try? response.line()).map { RemoteSocket.write($0, to: connection) }
                        close(connection)
                    }
                }
            }
        }
        source.setCancelHandler { [path] in
            close(descriptor)
            unlink(path)
        }
        source.resume()
        self.source = source
    }

    deinit {
        source?.cancel()
    }
}

enum RemoteClient {
    static func run(_ arguments: [String]) -> Never {
        if arguments.first == "help" {
            print(RemoteUsage().text)
            exit(0)
        }
        guard let request = try? RemoteRequest(arguments: arguments, folder: FileManager.default.currentDirectoryPath) else {
            fail(RemoteUsage().text, code: 64)
        }
        guard let descriptor = RemoteSocket.open(), RemoteSocket.with(RemoteSocket.path, { connect(descriptor, $0, $1) }) == 0 else {
            fail("Nada no responde. Ábrelo con «remote-control = true» en \(ConfigFile.url.path)", code: 69)
        }
        (try? request.line()).map { RemoteSocket.write($0, to: descriptor) }
        guard let response = try? RemoteResponse(line: RemoteSocket.readLine(descriptor)) else {
            fail("Nada cortó la conexión sin contestar", code: 70)
        }
        if !response.ok { fail(response.output, code: 1) }
        if !response.output.isEmpty { print(response.output) }
        exit(0)
    }

    private static func fail(_ message: String, code: Int32) -> Never {
        FileHandle.standardError.write(Data((message + "\n").utf8))
        exit(code)
    }
}
