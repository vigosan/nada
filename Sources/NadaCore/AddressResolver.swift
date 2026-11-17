import Foundation

public enum SearchEngine: String, CaseIterable {
    case duckDuckGo
    case google
    case brave

    public var title: String {
        switch self {
        case .duckDuckGo: "DuckDuckGo"
        case .google: "Google"
        case .brave: "Brave Search"
        }
    }

    public var next: SearchEngine {
        let all = SearchEngine.allCases
        return all[((all.firstIndex(of: self) ?? 0) + 1) % all.count]
    }

    public static func isResultsPage(_ url: URL) -> Bool {
        guard let page = URLComponents(url: url, resolvingAgainstBaseURL: false),
              page.queryItems?.contains(where: { $0.name == "q" }) == true else { return false }
        return allCases.contains { engine in
            guard let results = URLComponents(string: engine.queryPrefix) else { return false }
            return results.host == page.host && results.path == page.path
        }
    }

    var queryPrefix: String {
        switch self {
        case .duckDuckGo: "https://duckduckgo.com/?q="
        case .google: "https://www.google.com/search?q="
        case .brave: "https://search.brave.com/search?q="
        }
    }
}

public enum AddressResolver {
    public static func url(for input: String, searchEngine: SearchEngine = .duckDuckGo) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        guard isAddress(text) else { return searchURL(for: text, engine: searchEngine) }
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

    private static func searchURL(for text: String, engine: SearchEngine) -> URL? {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        guard let query = text.addingPercentEncoding(withAllowedCharacters: allowed) else { return nil }
        return URL(string: engine.queryPrefix + query)
    }
}
