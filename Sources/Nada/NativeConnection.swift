import Foundation
import NadaCore

final class NativeConnection {
    private let process = Process()
    private let input = Pipe()
    private let output = Pipe()
    private var messages = NativeMessages()
    var onMessage: ((Any) -> Void)?
    var onClose: (() -> Void)?

    static let folders = [
        URL.applicationSupportDirectory.appending(path: "Nada/NativeMessagingHosts"),
        URL.applicationSupportDirectory.appending(path: "Google/Chrome/NativeMessagingHosts"),
        URL(fileURLWithPath: "/Library/Google/Chrome/NativeMessagingHosts"),
    ]

    static func host(named name: String?, for identifier: String) -> NativeHost? {
        guard let name, let file = NativeHost.file(for: name) else { return nil }
        return folders.lazy
            .compactMap { try? Data(contentsOf: $0.appending(path: file)) }
            .compactMap { NativeHost(manifest: $0, name: name, extension: identifier) }
            .first
    }

    init(_ host: NativeHost) throws {
        signal(SIGPIPE, SIG_IGN)
        process.executableURL = URL(fileURLWithPath: host.path)
        process.arguments = [host.origin]
        process.standardInput = input
        process.standardOutput = output
        output.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let bytes = handle.availableData
            DispatchQueue.main.async { self?.received(bytes) }
        }
        try process.run()
    }

    func send(_ message: Any) {
        guard let json = try? JSONSerialization.data(withJSONObject: message, options: .fragmentsAllowed) else { return }
        try? input.fileHandleForWriting.write(contentsOf: NativeMessages.frame(json))
    }

    func close() {
        output.fileHandleForReading.readabilityHandler = nil
        if process.isRunning { process.terminate() }
        onClose?()
        onClose = nil
    }

    private func received(_ bytes: Data) {
        guard !bytes.isEmpty else {
            close()
            return
        }
        for message in messages.receive(bytes) {
            guard let value = try? JSONSerialization.jsonObject(with: message, options: .fragmentsAllowed) else { continue }
            onMessage?(value)
        }
    }
}
