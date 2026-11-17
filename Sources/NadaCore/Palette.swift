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
    case editKeyBindings
    case openSettingsSection(SettingsSection)
}

public enum SettingsSection: Equatable, Sendable {
    case shortcuts
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

    public init(id: String, title: String) {
        self.id = id
        self.title = title
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
        moduleCommands: [ModuleCommand] = [],
        searchEngine: SearchEngine = .duckDuckGo,
        bindings: KeyBindings = KeyBindings(config: ""),
        history: History = History()
    ) -> [PaletteItem] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let commands = commands(tabTitles: tabTitles, moduleCommands: moduleCommands, bindings: bindings)
        guard !text.isEmpty, let url = AddressResolver.url(for: text, searchEngine: searchEngine) else { return commands }
        let matches = matching(commands, text)
        let visited = history.matches(for: text)
        let strong = visited.strong.map(item)
        let weak = visited.weak.map(item)
        if AddressResolver.isAddress(text) {
            return strong + [PaletteItem(title: "Abrir \(text)", shortcut: "↵", action: .open(url))] + matches + weak
        }
        return strong + matches + weak + [PaletteItem(title: "Buscar «\(text)»", shortcut: "↵", action: .open(url))]
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
        let shortcuts = [PaletteItem(title: "Editar atajos de teclado", shortcut: "~/.config/nada/config", action: .editKeyBindings)]
            + Command.all.map { PaletteItem(title: $0.title, shortcut: bindings.label(for: $0.action), action: .editKeyBindings) }
        if section == .shortcuts { return text.isEmpty ? shortcuts : matching(shortcuts, text) }
        let root = settings.map { PaletteItem(title: $0.title, shortcut: $0.value, action: .changeSetting($0.id)) }
            + [PaletteItem(title: "Atajos de teclado", shortcut: "›", action: .openSettingsSection(.shortcuts))]
        return text.isEmpty ? root : matching(root + shortcuts, text)
    }

    public static func findItems(query: String) -> [PaletteItem] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }
        return [
            PaletteItem(title: "Siguiente coincidencia", shortcut: "↵", action: .find(text, backwards: false)),
            PaletteItem(title: "Coincidencia anterior", shortcut: "", action: .find(text, backwards: true)),
        ]
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

    private static func commands(tabTitles: [String], moduleCommands: [ModuleCommand], bindings: KeyBindings) -> [PaletteItem] {
        let hidden: [PaletteAction] = [.togglePalette, .openLocation]
        return Command.all.filter { command in
            if case .selectTab = command.action { return false }
            return !hidden.contains(command.action)
        }.map {
            PaletteItem(title: $0.title, shortcut: bindings.label(for: $0.action), action: $0.action)
        } + moduleCommands.map {
            PaletteItem(title: $0.title, shortcut: "", action: .module($0.id))
        } + tabTitles.enumerated().map { index, title in
            PaletteItem(title: "Ir a pestaña: \(title)", shortcut: bindings.label(for: .selectTab(index)), action: .selectTab(index))
        }
    }
}
