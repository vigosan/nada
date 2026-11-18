import Foundation

public enum ChromeStore {
    public static func identifier(in text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isIdentifier: (String) -> Bool = { $0.count == 32 && $0.allSatisfy { ("a"..."p").contains($0) } }
        if isIdentifier(trimmed) { return trimmed }
        guard let url = URL(string: trimmed), let host = url.host() else { return nil }
        if host == "consent.google.com" {
            let target = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "continue" }?.value
            return target.flatMap { $0.contains("consent.google.com") ? nil : identifier(in: $0) }
        }
        guard ["chromewebstore.google.com", "chrome.google.com"].contains(host),
              url.pathComponents.contains("detail") else { return nil }
        return url.pathComponents.last.flatMap { isIdentifier($0) ? $0 : nil }
    }

    public static func download(_ identifier: String) -> URL {
        var components = URLComponents(string: "https://clients2.google.com/service/update2/crx")!
        components.percentEncodedQuery =
            "response=redirect&prodversion=134.0&acceptformat=crx3&x=id%3D\(identifier)%26uc"
        return components.url!
    }

    public static func archive(in package: Data) -> Data? {
        let bytes = [UInt8](package.prefix(12))
        guard bytes.count == 12, bytes.prefix(4).elementsEqual("Cr24".utf8), bytes[4] == 3 else { return nil }
        let header = bytes[8...11].reversed().reduce(0) { $0 << 8 | Int($1) }
        guard package.count > 12 + header + 4 else { return nil }
        let archive = package.dropFirst(12 + header)
        return archive.prefix(4).elementsEqual([0x50, 0x4B, 0x03, 0x04]) ? Data(archive) : nil
    }
}
