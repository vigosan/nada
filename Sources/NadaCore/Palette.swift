import Foundation

public enum PaletteAction: Equatable, Sendable {
    case open(URL)
    case newTab
    case closeTab
    case reload
    case back
    case forward
    case toggleDevTools
    case selectTab(Int)
    case module(String)
    case openSettings
    case changeSetting(String)
    case togglePalette
    case openLocation
    case split(SplitAxis)
    case focusPane(Direction)
    case resizePane(Direction)
    case cyclePane(forward: Bool)
    case toggleFullscreen
    case zoomPane
    case nextTab
    case previousTab
    case equalizePanes
    case reopenTab
    case zoomIn
    case zoomOut
    case resetZoom
    case startFind
    case findNext
    case findPrevious
    case find(String, backwards: Bool)
    case clearHistory
    case clearSiteData
    case reloadConfig
    case editKeyBindings
    case openSettingsSection(SettingsSection)
    case bookmarkPage
    case openBookmarks
    case saveBookmark(category: String)
    case removeBookmark
    case openBookmarkCategory(String)
    case openDownloads
    case download(Int)
    case openDownloadedFile(Int)
    case revealDownload(Int)
    case cancelDownload(Int)
    case clearDownloads
}

public enum SettingsSection: Equatable, Sendable {
    case shortcuts
    case shortcutGroup(CommandGroup)

    public var parent: SettingsSection? {
        self == .shortcuts ? nil : .shortcuts
    }

    public var path: String {
        switch self {
        case .shortcuts: "Ajustes › Atajos de teclado"
        case .shortcutGroup(let group): "Ajustes › Atajos de teclado › \(group.title)"
        }
    }
}

public struct Setting: Equatable {
    public let id: String
    public let title: String
    public let value: String

    public init(id: String, title: String, value: String) {
        self.id = id
        self.title = title
        self.value = value
    }
}

public struct ModuleCommand: Equatable {
    public let id: String
    public let title: String
    public let shortcut: String

    public init(id: String, title: String, shortcut: String = "") {
        self.id = id
        self.title = title
        self.shortcut = shortcut
    }
}

public struct PaletteItem: Equatable {
    public let title: String
    public let shortcut: String
    public let action: PaletteAction
}

public enum Palette {
    public static func items(
        query: String,
        tabTitles: [String],
        activeTab: Int? = nil,
        moduleCommands: [ModuleCommand] = [],
        searchEngine: SearchEngine = .duckDuckGo,
        bindings: KeyBindings = KeyBindings(config: ""),
        history: History = History(),
        bookmarks: Bookmarks = Bookmarks()
    ) -> [PaletteItem] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let commands = commands(tabTitles: tabTitles, activeTab: activeTab, moduleCommands: moduleCommands, bindings: bindings)
        guard !text.isEmpty, let url = AddressResolver.url(for: text, searchEngine: searchEngine) else { return commands }
        let matches = matching(commands, text)
        let marked = Array(bookmarks.matches(for: text).prefix(5))
        let visited = history.matches(for: text)
        let unmarked: (HistoryEntry) -> Bool = { entry in !marked.contains { $0.url == entry.url } }
        let strong = visited.strong.filter(unmarked).map(item)
        let weak = visited.weak.filter(unmarked).map(item)
        let starred = marked.map(starredItem)
        if AddressResolver.isAddress(text) {
            return strong + [PaletteItem(title: "Abrir \(text)", shortcut: "↵", action: .open(url))] + starred + matches + weak
        }
        return strong + starred + matches + weak + [PaletteItem(title: "Buscar «\(text)»", shortcut: "↵", action: .open(url))]
    }

    public static func window(selected: Int, count: Int, size: Int) -> Range<Int> {
        let start = max(0, min(selected - size / 2, count - size))
        return start..<min(count, start + size)
    }

    public static func settingsItems(
        query: String,
        settings: [Setting],
        bindings: KeyBindings = KeyBindings(config: ""),
        section: SettingsSection? = nil
    ) -> [PaletteItem] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let shortcut: (Command) -> PaletteItem = {
            PaletteItem(title: $0.title, shortcut: bindings.label(for: $0.action), action: .editKeyBindings)
        }
        let shortcuts = Command.all.map(shortcut)
        switch section {
        case .shortcutGroup(let group):
            let items = Command.all.filter { $0.group == group }.map(shortcut)
            return text.isEmpty ? items : matching(items, text)
        case .shortcuts:
            let items = [PaletteItem(title: "Editar atajos de teclado", shortcut: "~/.config/nada/config", action: .editKeyBindings)]
                + CommandGroup.allCases.map {
                    PaletteItem(title: $0.title, shortcut: "›", action: .openSettingsSection(.shortcutGroup($0)))
                }
            return text.isEmpty ? items : matching(items + shortcuts, text)
        case nil:
            let root = settings.map { PaletteItem(title: $0.title, shortcut: $0.value, action: .changeSetting($0.id)) }
                + [PaletteItem(title: "Atajos de teclado", shortcut: "›", action: .openSettingsSection(.shortcuts))]
            return text.isEmpty ? root : matching(root + shortcuts, text)
        }
    }

    public static func findItems(query: String) -> [PaletteItem] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }
        return [
            PaletteItem(title: "Siguiente coincidencia", shortcut: "↵", action: .find(text, backwards: false)),
            PaletteItem(title: "Coincidencia anterior", shortcut: "", action: .find(text, backwards: true)),
        ]
    }

    public static func bookmarkSaveItems(query: String, bookmarks: Bookmarks, page: URL) -> [PaletteItem] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let removal = bookmarks.bookmark(for: page).map {
            [PaletteItem(title: "Quitar de marcadores", shortcut: $0.category, action: .removeBookmark)]
        } ?? []
        let categories = [Bookmarks.uncategorized] + bookmarks.categories.filter { $0 != Bookmarks.uncategorized }
        let choices = categories.map { PaletteItem(title: $0, shortcut: "", action: .saveBookmark(category: $0)) }
        guard !text.isEmpty else { return removal + choices }
        let exists = categories.contains {
            $0.compare(text, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        let creation = exists ? [] : [
            PaletteItem(title: "Crear categoría «\(text)»", shortcut: "↵", action: .saveBookmark(category: text)),
        ]
        return matching(removal + choices, text) + creation
    }

    public static func bookmarkItems(query: String, bookmarks: Bookmarks, category: String?) -> [PaletteItem] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if let category {
            let items = bookmarks.items(in: category).map {
                PaletteItem(title: $0.title, shortcut: $0.url.host() ?? "", action: .open($0.url))
            }
            return text.isEmpty ? items : matching(items, text)
        }
        guard text.isEmpty else { return bookmarks.matches(for: text).map(starredItem) }
        return bookmarks.categories.map {
            PaletteItem(title: $0, shortcut: "\(bookmarks.items(in: $0).count) ›", action: .openBookmarkCategory($0))
        }
    }

    public static func downloadItems(query: String, downloads: DownloadList, selected: Int?) -> [PaletteItem] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if let selected {
            switch downloads.items.first(where: { $0.id == selected })?.state {
            case .running:
                return [PaletteItem(title: "Cancelar descarga", shortcut: "↵", action: .cancelDownload(selected))]
            case .finished:
                return [
                    PaletteItem(title: "Abrir", shortcut: "↵", action: .openDownloadedFile(selected)),
                    PaletteItem(title: "Mostrar en Finder", shortcut: "", action: .revealDownload(selected)),
                ]
            default:
                return []
            }
        }
        let items = downloads.items.map { download in
            let state = switch download.state {
            case .running(let fraction): "\(Int(fraction * 100)) % ›"
            case .finished: "Hecha ›"
            case .failed: "Falló"
            case .cancelled: "Cancelada"
            }
            return PaletteItem(title: download.name, shortcut: state, action: .download(download.id))
        }
        let settled = downloads.items.count - downloads.running
        let clearing = settled == 0 ? [] : [PaletteItem(title: "Vaciar lista", shortcut: "\(settled)", action: .clearDownloads)]
        return text.isEmpty ? items + clearing : matching(items + clearing, text)
    }

    private static func starredItem(for bookmark: Bookmark) -> PaletteItem {
        PaletteItem(title: bookmark.title, shortcut: "★ \(bookmark.category)", action: .open(bookmark.url))
    }

    private static func item(for entry: HistoryEntry) -> PaletteItem {
        PaletteItem(
            title: entry.title.isEmpty ? entry.url.absoluteString : entry.title,
            shortcut: entry.url.host() ?? "",
            action: .open(entry.url)
        )
    }

    private static func matching(_ items: [PaletteItem], _ text: String) -> [PaletteItem] {
        items.filter { $0.title.range(of: text, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    private static func commands(
        tabTitles: [String],
        activeTab: Int?,
        moduleCommands: [ModuleCommand],
        bindings: KeyBindings
    ) -> [PaletteItem] {
        tabTitles.enumerated().filter { $0.offset != activeTab }.map { index, title in
            PaletteItem(title: "Ir a pestaña: \(title)", shortcut: bindings.label(for: .selectTab(index)), action: .selectTab(index))
        } + Command.all.filter { command in
            switch command.action {
            case .selectTab, .focusPane, .resizePane, .cyclePane, .togglePalette, .openLocation: false
            default: true
            }
        }.map {
            PaletteItem(title: $0.title, shortcut: bindings.label(for: $0.action), action: $0.action)
        } + moduleCommands.map {
            PaletteItem(title: $0.title, shortcut: $0.shortcut, action: .module($0.id))
        }
    }
}
