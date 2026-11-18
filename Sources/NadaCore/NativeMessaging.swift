import Foundation

public struct NativeHost: Equatable {
    public let path: String
    public let origin: String

    public init?(manifest: Data, name: String, extension identifier: String) {
        let origin = "chrome-extension://\(identifier)/"
        guard let json = (try? JSONSerialization.jsonObject(with: manifest)) as? [String: Any],
              json["name"] as? String == name,
              json["type"] as? String == "stdio",
              let path = json["path"] as? String,
              (json["allowed_origins"] as? [String])?.contains(origin) == true else { return nil }
        self.path = path
        self.origin = origin
    }

    public static func file(for name: String) -> String? {
        let allowed = name.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == ".") }
        guard !name.isEmpty, allowed, !name.hasPrefix("."), !name.contains("..") else { return nil }
        return "\(name).json"
    }
}

public struct NativeMessages {
    private var pending = Data()

    public init() {}

    public static func frame(_ message: Data) -> Data {
        withUnsafeBytes(of: UInt32(message.count).littleEndian) { Data($0) } + message
    }

    public mutating func receive(_ bytes: Data) -> [Data] {
        pending.append(bytes)
        var messages: [Data] = []
        while pending.count >= 4 {
            let size = pending.prefix(4).reversed().reduce(0) { $0 << 8 | Int($1) }
            guard pending.count >= 4 + size else { break }
            messages.append(Data(pending.dropFirst(4).prefix(size)))
            pending = Data(pending.dropFirst(4 + size))
        }
        return messages
    }
}
