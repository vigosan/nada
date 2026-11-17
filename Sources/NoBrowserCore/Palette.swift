import Foundation

public enum PaletteAction: Equatable {
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
        searchEngine: SearchEngine = .duckDuckGo
    ) -> [PaletteItem] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let commands = commands(tabTitles: tabTitles, moduleCommands: moduleCommands)
        guard !text.isEmpty, let url = AddressResolver.url(for: text, searchEngine: searchEngine) else { return commands }
        let matches = matching(commands, text)
        if AddressResolver.isAddress(text) {
            return [PaletteItem(title: "Abrir \(text)", shortcut: "↵", action: .open(url))] + matches
        }
        return matches + [PaletteItem(title: "Buscar «\(text)»", shortcut: "↵", action: .open(url))]
    }

    public static func settingsItems(query: String, settings: [Setting]) -> [PaletteItem] {
        let items = settings.map { PaletteItem(title: $0.title, shortcut: $0.value, action: .changeSetting($0.id)) }
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? items : matching(items, text)
    }

    private static func matching(_ items: [PaletteItem], _ text: String) -> [PaletteItem] {
        items.filter { $0.title.range(of: text, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }

    private static func commands(tabTitles: [String], moduleCommands: [ModuleCommand]) -> [PaletteItem] {
        [
            PaletteItem(title: "Pestaña nueva", shortcut: "⌘T", action: .newTab),
            PaletteItem(title: "Cerrar pestaña", shortcut: "⌘W", action: .closeTab),
            PaletteItem(title: "Recargar", shortcut: "⌘R", action: .reload),
            PaletteItem(title: "Atrás", shortcut: "⌘[", action: .back),
            PaletteItem(title: "Adelante", shortcut: "⌘]", action: .forward),
            PaletteItem(title: "Herramientas de desarrollador", shortcut: "⌥⌘I", action: .toggleDevTools),
            PaletteItem(title: "Ajustes", shortcut: "⌘,", action: .openSettings),
            PaletteItem(title: "Dividir a la derecha", shortcut: "⌘D", action: .split(.horizontal)),
            PaletteItem(title: "Dividir abajo", shortcut: "⇧⌘D", action: .split(.vertical)),
        ] + moduleCommands.map {
            PaletteItem(title: $0.title, shortcut: "", action: .module($0.id))
        } + tabTitles.enumerated().map { index, title in
            PaletteItem(title: "Ir a pestaña: \(title)", shortcut: index < 9 ? "⌘\(index + 1)" : "", action: .selectTab(index))
        }
    }
}
