public struct KeyCombo: Equatable {
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

public struct Command: Sendable {
    public let name: String
    public let title: String
    public let action: PaletteAction

    public static let all: [Command] = [
        Command(name: "palette", title: "Paleta de órdenes", action: .togglePalette),
        Command(name: "open_location", title: "Abrir dirección", action: .openLocation),
        Command(name: "new_tab", title: "Pestaña nueva", action: .newTab),
        Command(name: "close", title: "Cerrar panel o pestaña", action: .closeTab),
        Command(name: "reload", title: "Recargar", action: .reload),
        Command(name: "back", title: "Atrás", action: .back),
        Command(name: "forward", title: "Adelante", action: .forward),
        Command(name: "dev_tools", title: "Herramientas de desarrollador", action: .toggleDevTools),
        Command(name: "settings", title: "Ajustes", action: .openSettings),
        Command(name: "split_right", title: "Dividir a la derecha", action: .split(.horizontal)),
        Command(name: "split_down", title: "Dividir abajo", action: .split(.vertical)),
        Command(name: "focus_left", title: "Ir al panel de la izquierda", action: .focusPane(.left)),
        Command(name: "focus_right", title: "Ir al panel de la derecha", action: .focusPane(.right)),
        Command(name: "focus_up", title: "Ir al panel de arriba", action: .focusPane(.up)),
        Command(name: "focus_down", title: "Ir al panel de abajo", action: .focusPane(.down)),
        Command(name: "resize_left", title: "Mover divisor a la izquierda", action: .resizePane(.left)),
        Command(name: "resize_right", title: "Mover divisor a la derecha", action: .resizePane(.right)),
        Command(name: "resize_up", title: "Mover divisor arriba", action: .resizePane(.up)),
        Command(name: "resize_down", title: "Mover divisor abajo", action: .resizePane(.down)),
        Command(name: "zoom_pane", title: "Ampliar o restaurar panel", action: .zoomPane),
        Command(name: "fullscreen", title: "Pantalla completa", action: .toggleFullscreen),
        Command(name: "next_tab", title: "Pestaña siguiente", action: .nextTab),
        Command(name: "previous_tab", title: "Pestaña anterior", action: .previousTab),
        Command(name: "reopen_tab", title: "Reabrir pestaña cerrada", action: .reopenTab),
        Command(name: "equalize_panes", title: "Igualar paneles", action: .equalizePanes),
        Command(name: "zoom_in", title: "Acercar página", action: .zoomIn),
        Command(name: "zoom_out", title: "Alejar página", action: .zoomOut),
        Command(name: "reset_zoom", title: "Tamaño real de la página", action: .resetZoom),
        Command(name: "find", title: "Buscar en la página", action: .startFind),
        Command(name: "find_next", title: "Siguiente coincidencia", action: .findNext),
        Command(name: "find_previous", title: "Coincidencia anterior", action: .findPrevious),
    ] + (1...9).map { Command(name: "goto_tab:\($0)", title: "Pestaña \($0)", action: .selectTab($0 - 1)) }
}

public struct KeyBindings {
    public private(set) var bindings: [(combo: KeyCombo, action: PaletteAction)] = []
    public private(set) var errors: [String] = []

    public init(config: String) {
        for (combo, name) in Self.defaults {
            bind(combo, to: name, line: 0)
        }
        for (index, line) in config.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2, parts[0] == "keybind", let separator = parts[1].lastIndex(of: "=") else { continue }
            bind(
                parts[1][..<separator].trimmingCharacters(in: .whitespaces),
                to: parts[1][parts[1].index(after: separator)...].trimmingCharacters(in: .whitespaces),
                line: index + 1
            )
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
        ("cmd+k", "palette"), ("cmd+l", "open_location"), ("cmd+t", "new_tab"), ("cmd+w", "close"),
        ("cmd+r", "reload"), ("cmd+[", "back"), ("cmd+]", "forward"), ("cmd+opt+i", "dev_tools"),
        ("cmd+,", "settings"), ("cmd+d", "split_right"), ("cmd+shift+d", "split_down"),
        ("cmd+opt+left", "focus_left"), ("cmd+opt+right", "focus_right"),
        ("cmd+opt+up", "focus_up"), ("cmd+opt+down", "focus_down"),
        ("cmd+ctrl+left", "resize_left"), ("cmd+ctrl+right", "resize_right"),
        ("cmd+ctrl+up", "resize_up"), ("cmd+ctrl+down", "resize_down"),
        ("cmd+shift+return", "zoom_pane"), ("cmd+return", "fullscreen"),
        ("cmd+shift+]", "next_tab"), ("cmd+shift+[", "previous_tab"),
        ("ctrl+tab", "next_tab"), ("ctrl+shift+tab", "previous_tab"),
        ("cmd+shift+t", "reopen_tab"), ("cmd+ctrl+=", "equalize_panes"),
        ("cmd+=", "zoom_in"), ("cmd+plus", "zoom_in"), ("cmd+-", "zoom_out"), ("cmd+0", "reset_zoom"),
        ("cmd+f", "find"), ("cmd+g", "find_next"), ("cmd+shift+g", "find_previous"),
    ] + (1...9).map { ("cmd+\($0)", "goto_tab:\($0)") }
}
