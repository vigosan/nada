import Foundation
import NadaCore

final class Library {
    private static let historyFile = URL.applicationSupportDirectory.appending(path: "Nada/history.json")
    private static let bookmarksFile = URL.applicationSupportDirectory.appending(path: "Nada/bookmarks.json")
    var history = (try? JSONDecoder().decode(History.self, from: Data(contentsOf: historyFile))) ?? History()
    var bookmarks = (try? JSONDecoder().decode(Bookmarks.self, from: Data(contentsOf: bookmarksFile))) ?? Bookmarks()
    private var historySave: DispatchWorkItem?

    static func save(_ value: some Encodable, to file: URL) {
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(value).write(to: file, options: .atomic)
        } catch {
            NSLog("No se pudo guardar %@: %@", file.lastPathComponent, "\(error)")
        }
    }

    func saveHistory() {
        historySave?.cancel()
        Self.save(history, to: Self.historyFile)
    }

    func saveHistorySoon() {
        historySave?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let snapshot = self?.history else { return }
            DispatchQueue.global(qos: .utility).async { Self.save(snapshot, to: Self.historyFile) }
        }
        historySave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: work)
    }

    func saveBookmarks() {
        Self.save(bookmarks, to: Self.bookmarksFile)
    }
}
