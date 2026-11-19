import Foundation

public struct ConfigEntry: Equatable, Sendable {
    public let key: String
    public let value: String
    public let line: Int
}

public struct Config: Sendable {
    public static let keys = [
        "theme", "background", "foreground", "font-family",
        "unfocused-split-opacity", "unfocused-split-fill", "split-divider-color", "split-preserve-zoom",
        "window-save-state", "fullscreen", "maximize", "remote-control", "config-file", "keybind",
    ]

    public static let template = ([
        "# Configuración de Nada, con la sintaxis de Ghostty.",
        "# Quita el # de una línea para activarla y pulsa ⇧⌘, para recargar sin reiniciar.",
        "#",
        "# theme = light:TokyoNight Day,dark:TokyoNight",
        "# background = #1a1b26",
        "# foreground = #c0caf5",
        "# font-family = MonoLisa",
        "# unfocused-split-opacity = 0.7",
        "# unfocused-split-fill = #000000",
        "# split-divider-color = #2b2d3b",
        "# split-preserve-zoom = navigation",
        "# window-save-state = default",
        "# fullscreen = false",
        "# maximize = false",
        "# remote-control = false",
        "# config-file = ?otro-archivo",
        "# keybind = ctrl+h=focus_left",
        "#",
        "# En keybind: modificadores cmd, ctrl, opt, shift; teclas de un carácter, o left, right, up, down,",
        "# return, tab, plus. «unbind» libera una combinación y «clear» quita todos los atajos de fábrica.",
        "# Órdenes:",
    ] + Command.all.map { "#   \($0.name)  \($0.title)" }).joined(separator: "\n") + "\n"

    public let entries: [ConfigEntry]
    public let errors: [String]
    public let keyBindings: KeyBindings

    public init(text: String, include: (String) -> String? = { _ in nil }) {
        var problems: [String] = []
        var included: Set<String> = []
        let parsed = Self.parse(text, include: include, included: &included, problems: &problems)
        var valid: [ConfigEntry] = []
        for entry in parsed {
            if Self.accepts(entry) {
                valid.append(entry)
            } else {
                problems.append("línea \(entry.line): «\(entry.value)» no vale para \(entry.key)")
            }
        }
        entries = valid
        keyBindings = KeyBindings(entries: valid)
        errors = problems + keyBindings.errors
    }

    public func string(_ key: String) -> String? {
        entries.last { $0.key == key }?.value
    }

    public var theme: ThemeChoice {
        ThemeChoice(value: string("theme"))
    }

    public var background: RGB? {
        string("background").flatMap(RGB.init(hex:))
    }

    public var foreground: RGB? {
        string("foreground").flatMap(RGB.init(hex:))
    }

    public var fontFamily: String? {
        string("font-family")
    }

    public var unfocusedSplitOpacity: Double {
        min(1, max(0.15, string("unfocused-split-opacity").flatMap(Double.init) ?? 0.7))
    }

    public var unfocusedSplitFill: RGB? {
        string("unfocused-split-fill").flatMap(RGB.init(hex:))
    }

    public var splitDividerColor: RGB? {
        string("split-divider-color").flatMap(RGB.init(hex:))
    }

    public var preservesZoomOnNavigation: Bool {
        string("split-preserve-zoom") == "navigation"
    }

    public var restoresWindows: Bool {
        string("window-save-state") != "never"
    }

    public var startsFullscreen: Bool {
        string("fullscreen") == "true"
    }

    public var startsMaximized: Bool {
        string("maximize") == "true"
    }

    public var allowsRemoteControl: Bool {
        string("remote-control") == "true"
    }

    private static func accepts(_ entry: ConfigEntry) -> Bool {
        switch entry.key {
        case "unfocused-split-opacity": Double(entry.value) != nil
        case "background", "foreground", "unfocused-split-fill", "split-divider-color": RGB(hex: entry.value) != nil
        case "split-preserve-zoom": ["navigation", "no-navigation"].contains(entry.value)
        case "window-save-state": ["default", "never", "always"].contains(entry.value)
        case "fullscreen", "maximize", "remote-control": ["true", "false"].contains(entry.value)
        default: true
        }
    }

    private static func parse(
        _ text: String,
        include: (String) -> String?,
        included: inout Set<String>,
        problems: inout [String]
    ) -> [ConfigEntry] {
        var entries: [ConfigEntry] = []
        var files: [(path: String, line: Int)] = []
        for (index, raw) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let separator = line.firstIndex(of: "=") else {
                problems.append("línea \(index + 1): falta «=»")
                continue
            }
            let key = line[..<separator].trimmingCharacters(in: .whitespaces)
            var value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            if value.count >= 2, value.hasPrefix("\""), value.hasSuffix("\"") { value = String(value.dropFirst().dropLast()) }
            guard keys.contains(key) else {
                problems.append("línea \(index + 1): opción desconocida «\(key)»")
                continue
            }
            if key == "config-file" {
                files.append((value, index + 1))
            } else if value.isEmpty {
                entries.removeAll { $0.key == key }
            } else {
                entries.append(ConfigEntry(key: key, value: value, line: index + 1))
            }
        }
        for file in files {
            let optional = file.path.hasPrefix("?")
            let path = optional ? String(file.path.dropFirst()) : file.path
            guard included.insert(path).inserted else { continue }
            if let nested = include(path) {
                entries += parse(nested, include: include, included: &included, problems: &problems)
            } else if !optional {
                problems.append("línea \(file.line): no se puede leer «\(path)»")
            }
        }
        return entries
    }
}
