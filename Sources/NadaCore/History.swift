import Foundation

public struct HistoryEntry: Codable, Equatable {
    public var url: URL
    public var title: String
    public var visits: Int
    public var lastVisit: Date
}

public struct History: Codable {
    public private(set) var entries: [HistoryEntry] = []
    private var capacity: Int

    public init(capacity: Int = 5000) {
        self.capacity = capacity
    }

    public mutating func record(url: URL, title: String, at date: Date, newVisit: Bool) {
        guard !SearchEngine.isResultsPage(url) else { return }
        if let index = entries.firstIndex(where: { $0.url == url }) {
            entries[index].title = title
            entries[index].lastVisit = date
            entries[index].visits += newVisit ? 1 : 0
            return
        }
        entries.append(HistoryEntry(url: url, title: title, visits: 1, lastVisit: date))
        if entries.count > capacity, let oldest = entries.indices.min(by: { entries[$0].lastVisit < entries[$1].lastVisit }) {
            entries.remove(at: oldest)
        }
    }

    public mutating func clear() {
        entries = []
    }

    public func matches(for query: String) -> (strong: [HistoryEntry], weak: [HistoryEntry]) {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return ([], []) }
        let ranked = entries
            .filter { !SearchEngine.isResultsPage($0.url) }
            .sorted { ($0.visits, $0.lastVisit) > ($1.visits, $1.lastVisit) }
        let matchingHost = ranked.filter { Self.host(of: $0).hasPrefix(text) }
        let strong = matchingHost.filter(Self.isSiteRoot) + matchingHost.filter { !Self.isSiteRoot($0) }
        let weak = ranked.filter { entry in
            !Self.host(of: entry).hasPrefix(text) && [entry.url.absoluteString, entry.title].contains {
                $0.range(of: text, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
        }
        return (Array(strong.prefix(3)), Array(weak.prefix(5)))
    }

    private static func isSiteRoot(_ entry: HistoryEntry) -> Bool {
        ["", "/"].contains(entry.url.path()) && entry.url.query() == nil
    }

    private static func host(of entry: HistoryEntry) -> String {
        let host = entry.url.host()?.lowercased() ?? ""
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
