import Foundation

public struct RemoteUsage: Error {
    public let text = """
    uso:
      nada open <dirección o búsqueda>   abre una página
      nada tabs [--json]                 lista las pestañas
      nada eval <javascript>             ejecuta un script en la página activa
      nada text                          saca el texto de la página activa
      nada screenshot [fichero.png]      guarda una captura de la página activa
    """

    public init() {}
}

public enum RemoteRequest: Codable, Equatable {
    case open(String)
    case tabs(json: Bool)
    case eval(String)
    case text
    case screenshot(String)

    private static let names = ["open", "tabs", "eval", "text", "screenshot", "help"]

    public static func isCommand(_ word: String) -> Bool {
        names.contains(word)
    }

    public init(arguments: [String], folder: String) throws {
        let rest = Array(arguments.dropFirst())
        switch (arguments.first, rest.isEmpty) {
        case ("open", false): self = .open(rest.joined(separator: " "))
        case ("tabs", _): self = .tabs(json: rest.contains("--json"))
        case ("eval", false): self = .eval(rest.joined(separator: " "))
        case ("text", _): self = .text
        case ("screenshot", _):
            self = .screenshot(URL(fileURLWithPath: rest.first ?? "nada.png", relativeTo: URL(fileURLWithPath: folder, isDirectory: true)).standardizedFileURL.path)
        default: throw RemoteUsage()
        }
    }

    public init(line: some Collection<UInt8>) throws {
        self = try JSONDecoder().decode(Self.self, from: Data(line))
    }

    public func line() throws -> Data {
        try JSONEncoder().encode(self) + Data("\n".utf8)
    }
}

public struct RemoteResponse: Codable, Equatable {
    public var ok: Bool
    public var output: String

    public init(ok: Bool, output: String) {
        self.ok = ok
        self.output = output
    }

    public init(line: some Collection<UInt8>) throws {
        self = try JSONDecoder().decode(Self.self, from: Data(line))
    }

    public func line() throws -> Data {
        try JSONEncoder().encode(self) + Data("\n".utf8)
    }
}

public struct RemoteTab: Codable, Equatable {
    public var index: Int
    public var title: String
    public var url: String
    public var active: Bool

    public init(index: Int, title: String, url: String, active: Bool) {
        self.index = index
        self.title = title
        self.url = url
        self.active = active
    }

    public static func render(_ tabs: [RemoteTab], json: Bool) -> String {
        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            return (try? encoder.encode(tabs)).map { String(decoding: $0, as: UTF8.self) } ?? "[]"
        }
        return tabs.map { tab in
            let title = tab.title.replacing(/\s/, with: " ")
            return "\(tab.index)\t\(tab.active ? "*" : " ")\t\(title)\t\(tab.url)"
        }.joined(separator: "\n")
    }
}

public enum RemoteResult {
    public static func render(_ value: Any?) -> String {
        switch value {
        case nil, is NSNull:
            return ""
        case let text as String:
            return text
        case let number as NSNumber:
            return CFGetTypeID(number) == CFBooleanGetTypeID() ? (number.boolValue ? "true" : "false") : number.stringValue
        case let value?:
            guard JSONSerialization.isValidJSONObject(value),
                  let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys, .withoutEscapingSlashes])
            else { return "\(value)" }
            return String(decoding: data, as: UTF8.self)
        }
    }
}
