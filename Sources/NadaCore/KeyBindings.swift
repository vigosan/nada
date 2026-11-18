public struct KeyCombo: Equatable, Sendable {
    public struct Modifiers: OptionSet, Equatable, Sendable {
        public let rawValue: Int
        public static let control = Modifiers(rawValue: 1)
        public static let option = Modifiers(rawValue: 2)
        public static let shift = Modifiers(rawValue: 4)
        public static let command = Modifiers(rawValue: 8)

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    public let key: String
    public let modifiers: Modifiers

    public init?(_ text: String) {
        let parts = text.lowercased().split(separator: "+", omittingEmptySubsequences: false).map(String.init)
        guard let typed = parts.last else { return nil }
        let key = typed == "enter" ? "return" : typed
        guard key.count == 1 || Self.namedKeys[key] != nil else { return nil }
        var modifiers: Modifiers = []
        for name in parts.dropLast() {
            guard let modifier = Self.modifierNames[name] else { return nil }
            modifiers.insert(modifier)
        }
        guard !modifiers.isDisjoint(with: [.command, .control, .option]) else { return nil }
        self.key = key
        self.modifiers = modifiers
    }

    public var label: String {
        let symbols: [(Modifiers, String)] = [(.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")]
        return symbols.filter { modifiers.contains($0.0) }.map(\.1).joined() + (Self.namedKeys[key] ?? key.uppercased())
    }

    private static let namedKeys = [
        "left": "←", "right": "→", "up": "↑", "down": "↓", "return": "↩", "tab": "⇥", "plus": "+",
    ]
    private static let modifierNames: [String: Modifiers] = [
        "cmd": .command, "command": .command, "super": .command,
        "ctrl": .control, "control": .control,
        "opt": .option, "option": .option, "alt": .option,
        "shift": .shift,
    ]
}

public enum CommandGroup: CaseIterable, Equatable, Sendable {
    case page
    case tabs
    case panes
    case window

    public var title: String {
        switch self {
        case .page: "Página"
        case .tabs: "Pestañas"
        case .panes: "Paneles"
        case .window: "Ventana"
        }
    }
}

public struct Command: Sendable {
    public let name: String
    public let group: CommandGroup
    public let title: String
    public let action: PaletteAction

    public static let all: [Command] = [
        Command(name: "palette", group: .page, title: "Paleta de órdenes", action: .togglePalette),
        Command(name: "open_location", group: .page, title: "Abrir dirección", action: .openLocation),
        Command(name: "new_tab", group: .tabs, title: "Pestaña nueva", action: .newTab),
        Command(name: "new_window", group: .window, title: "Ventana nueva", action: .newWindow(private: false)),
        Command(name: "new_private_window", group: .window, title: "Ventana privada nueva", action: .newWindow(private: true)),
        Command(name: "close", group: .tabs, title: "Cerrar panel o pestaña", action: .closeTab),
        Command(name: "reload", group: .page, title: "Recargar", action: .reload),
        Command(name: "back", group: .page, title: "Atrás", action: .back),
        Command(name: "forward", group: .page, title: "Adelante", action: .forward),
        Command(name: "dev_tools", group: .window, title: "Herramientas de desarrollador", action: .toggleDevTools),
        Command(name: "settings", group: .window, title: "Ajustes", action: .openSettings),
        Command(name: "split_right", group: .panes, title: "Dividir a la derecha", action: .split(.horizontal)),
        Command(name: "split_down", group: .panes, title: "Dividir abajo", action: .split(.vertical)),
        Command(name: "focus_left", group: .panes, title: "Ir al panel de la izquierda", action: .focusPane(.left)),
        Command(name: "focus_right", group: .panes, title: "Ir al panel de la derecha", action: .focusPane(.right)),
        Command(name: "focus_up", group: .panes, title: "Ir al panel de arriba", action: .focusPane(.up)),
        Command(name: "focus_down", group: .panes, title: "Ir al panel de abajo", action: .focusPane(.down)),
        Command(name: "focus_next", group: .panes, title: "Ir al panel siguiente", action: .cyclePane(forward: true)),
        Command(name: "focus_previous", group: .panes, title: "Ir al panel anterior", action: .cyclePane(forward: false)),
        Command(name: "resize_left", group: .panes, title: "Mover divisor a la izquierda", action: .resizePane(.left)),
        Command(name: "resize_right", group: .panes, title: "Mover divisor a la derecha", action: .resizePane(.right)),
        Command(name: "resize_up", group: .panes, title: "Mover divisor arriba", action: .resizePane(.up)),
        Command(name: "resize_down", group: .panes, title: "Mover divisor abajo", action: .resizePane(.down)),
        Command(name: "zoom_pane", group: .panes, title: "Ampliar o restaurar panel", action: .zoomPane),
        Command(name: "fullscreen", group: .window, title: "Pantalla completa", action: .toggleFullscreen),
        Command(name: "reload_config", group: .window, title: "Recargar configuración", action: .reloadConfig),
        Command(name: "next_tab", group: .tabs, title: "Pestaña siguiente", action: .nextTab),
        Command(name: "previous_tab", group: .tabs, title: "Pestaña anterior", action: .previousTab),
        Command(name: "reopen_tab", group: .tabs, title: "Reabrir pestaña cerrada", action: .reopenTab),
        Command(name: "move_tab_left", group: .tabs, title: "Mover pestaña a la izquierda", action: .moveTab(forward: false)),
        Command(name: "move_tab_right", group: .tabs, title: "Mover pestaña a la derecha", action: .moveTab(forward: true)),
        Command(name: "duplicate_tab", group: .tabs, title: "Duplicar pestaña", action: .duplicateTab),
        Command(name: "equalize_panes", group: .panes, title: "Igualar paneles", action: .equalizePanes),
        Command(name: "zoom_in", group: .page, title: "Acercar página", action: .zoomIn),
        Command(name: "zoom_out", group: .page, title: "Alejar página", action: .zoomOut),
        Command(name: "reset_zoom", group: .page, title: "Tamaño real de la página", action: .resetZoom),
        Command(name: "find", group: .page, title: "Buscar en la página", action: .startFind),
        Command(name: "find_next", group: .page, title: "Siguiente coincidencia", action: .findNext),
        Command(name: "find_previous", group: .page, title: "Coincidencia anterior", action: .findPrevious),
        Command(name: "clear_history", group: .page, title: "Borrar historial", action: .clearHistory),
        Command(name: "clear_site_data", group: .page, title: "Borrar cookies y datos de sitios", action: .clearSiteData),
        Command(name: "bookmarks", group: .page, title: "Marcadores", action: .openBookmarks),
        Command(name: "bookmark_page", group: .page, title: "Guardar en marcadores", action: .bookmarkPage),
        Command(name: "downloads", group: .page, title: "Descargas", action: .openDownloads),
    ] + (1...9).map { Command(name: "goto_tab:\($0)", group: .tabs, title: "Pestaña \($0)", action: .selectTab($0 - 1)) }
}

public struct KeyBindings: Sendable {
    public private(set) var bindings: [(combo: KeyCombo, action: PaletteAction)] = []
    public private(set) var errors: [String] = []

    public init(config: String) {
        self.init(entries: Config(text: config).entries)
    }

    public init(entries: [ConfigEntry]) {
        for (combo, name) in Self.defaults {
            bind(combo, to: name, line: 0)
        }
        for entry in entries where entry.key == "keybind" {
            if entry.value == "clear" {
                bindings = []
            } else if let separator = entry.value.lastIndex(of: "=") {
                bind(
                    entry.value[..<separator].trimmingCharacters(in: .whitespaces),
                    to: entry.value[entry.value.index(after: separator)...].trimmingCharacters(in: .whitespaces),
                    line: entry.line
                )
            } else {
                errors.append("línea \(entry.line): atajo no válido «\(entry.value)»")
            }
        }
    }

    public func action(for combo: KeyCombo) -> PaletteAction? {
        bindings.first { $0.combo == combo }?.action
    }

    public func label(for action: PaletteAction) -> String {
        bindings.last { $0.action == action }?.combo.label ?? ""
    }

    private mutating func bind(_ comboText: String, to name: String, line: Int) {
        guard let combo = KeyCombo(comboText) else {
            errors.append("línea \(line): combinación no válida «\(comboText)»")
            return
        }
        if name == "unbind" {
            bindings.removeAll { $0.combo == combo }
            return
        }
        guard let action = Command.all.first(where: { $0.name == name })?.action else {
            errors.append("línea \(line): orden desconocida «\(name)»")
            return
        }
        bindings.removeAll { $0.combo == combo }
        bindings.append((combo, action))
    }

    private static let defaults: [(String, String)] = [
        ("cmd+k", "palette"), ("cmd+l", "open_location"), ("cmd+t", "new_tab"), ("cmd+n", "new_window"), ("cmd+shift+n", "new_private_window"),
        ("cmd+w", "close"),
        ("cmd+r", "reload"), ("cmd+left", "back"), ("cmd+right", "forward"), ("cmd+opt+i", "dev_tools"),
        ("cmd+,", "settings"), ("cmd+shift+,", "reload_config"), ("cmd+d", "split_right"), ("cmd+shift+d", "split_down"),
        ("cmd+opt+left", "focus_left"), ("cmd+opt+right", "focus_right"),
        ("cmd+opt+up", "focus_up"), ("cmd+opt+down", "focus_down"),
        ("cmd+]", "focus_next"), ("cmd+[", "focus_previous"),
        ("cmd+ctrl+left", "resize_left"), ("cmd+ctrl+right", "resize_right"),
        ("cmd+ctrl+up", "resize_up"), ("cmd+ctrl+down", "resize_down"),
        ("cmd+shift+return", "zoom_pane"), ("cmd+return", "fullscreen"),
        ("cmd+shift+]", "next_tab"), ("cmd+shift+[", "previous_tab"),
        ("ctrl+tab", "next_tab"), ("ctrl+shift+tab", "previous_tab"),
        ("cmd+opt+shift+left", "move_tab_left"), ("cmd+opt+shift+right", "move_tab_right"),
        ("cmd+shift+t", "reopen_tab"), ("cmd+ctrl+=", "equalize_panes"),
        ("cmd+=", "zoom_in"), ("cmd+plus", "zoom_in"), ("cmd+-", "zoom_out"), ("cmd+0", "reset_zoom"),
        ("cmd+b", "bookmark_page"), ("cmd+opt+b", "bookmarks"), ("cmd+opt+l", "downloads"),
        ("cmd+f", "find"), ("cmd+g", "find_next"), ("cmd+shift+g", "find_previous"),
    ] + (1...9).map { ("cmd+\($0)", "goto_tab:\($0)") }
}
