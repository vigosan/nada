import Foundation

public struct Bookmark: Codable, Equatable {
    public var url: URL
    public var title: String
    public var category: String
}

public struct Bookmarks: Codable {
    public static let uncategorized = "Sin categoría"

    public private(set) var items: [Bookmark] = []

    public init() {}

    public var categories: [String] {
        Set(items.map(\.category)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    public func bookmark(for url: URL) -> Bookmark? {
        items.first { $0.url == url }
    }

    public func items(in category: String) -> [Bookmark] {
        items.filter { $0.category == category }
    }

    public func matches(for query: String) -> [Bookmark] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }
        return items.filter { bookmark in
            [bookmark.title, bookmark.url.absoluteString, bookmark.category].contains {
                $0.range(of: text, options: [.caseInsensitive, .diacriticInsensitive]) != nil
            }
        }
    }

    public mutating func save(url: URL, title: String, category: String) {
        let bookmark = Bookmark(url: url, title: title, category: category)
        if let index = items.firstIndex(where: { $0.url == url }) {
            items[index] = bookmark
        } else {
            items.append(bookmark)
        }
    }

    public mutating func remove(url: URL) {
        items.removeAll { $0.url == url }
    }
}
