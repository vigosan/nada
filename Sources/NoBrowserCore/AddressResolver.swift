import Foundation

public enum AddressResolver {
    public static func url(for input: String) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        guard isAddress(text) else { return searchURL(for: text) }
        if hasScheme(text) { return URL(string: text) }
        return URL(string: (isLocal(host(of: text)) ? "http://" : "https://") + text)
    }

    public static func isAddress(_ input: String) -> Bool {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !text.contains(where: \.isWhitespace) else { return false }
        if hasScheme(text) { return true }
        let host = host(of: text)
        return host == "localhost" || (host.contains(".") && !host.hasPrefix(".") && !host.hasSuffix("."))
    }

    private static func hasScheme(_ text: String) -> Bool {
        text.range(of: "^[a-zA-Z][a-zA-Z0-9+.-]*://", options: .regularExpression) != nil
    }

    private static func host(of text: String) -> Substring {
        text.prefix { $0 != "/" && $0 != ":" }
    }

    private static func isLocal(_ host: Substring) -> Bool {
        host == "localhost" || host.allSatisfy { $0.isNumber || $0 == "." }
    }

    private static func searchURL(for text: String) -> URL? {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        guard let query = text.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        return URL(string: "https://duckduckgo.com/?q=" + query)
    }
}
