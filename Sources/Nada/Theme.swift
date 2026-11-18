import AppKit
import NadaCore

enum Theme {
    static var colors = ThemeColors.fallback
    static var name = "nada"

    static var window: NSColor { color(colors.background) }
    static var bar: NSColor { color(colors.bar) }
    static var raised: NSColor { color(colors.raised) }
    static var text: NSColor { color(colors.foreground) }
    static var accent: NSColor { color(colors.accent) }
    static var dim: NSColor { color(colors.dim) }

    static func load(_ choice: ThemeChoice) {
        let dark = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let wanted = choice.name(dark: dark)
        let folders = [
            URL.homeDirectory.appending(path: ".config/nada/themes"),
            URL.homeDirectory.appending(path: ".config/ghostty/themes"),
            URL(fileURLWithPath: "/Applications/Ghostty.app/Contents/Resources/ghostty/themes"),
        ]
        let file = folders.lazy.compactMap { folder in
            (try? FileManager.default.contentsOfDirectory(atPath: folder.path))?
                .first { $0.caseInsensitiveCompare(wanted) == .orderedSame }
                .map { folder.appending(path: $0) }
        }.first
        let text = file.flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? ThemeColors.builtIn[wanted.lowercased()]
        if let loaded = text.flatMap(ThemeColors.init(ghostty:)) {
            colors = loaded
            name = wanted
        } else {
            NSLog("Tema «%@» no encontrado o no válido; se usa el tema propio de Nada", wanted)
            colors = ThemeColors.builtIn[dark ? "nada" : "nada-light"].flatMap(ThemeColors.init(ghostty:)) ?? .fallback
            name = dark ? "nada" : "nada-light"
        }
    }

    private static func color(_ rgb: RGB) -> NSColor {
        NSColor(srgbRed: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
    }

    static func label(_ string: String, color: NSColor, font: NSFont) -> NSTextField {
        let label = NSTextField(labelWithString: string)
        label.textColor = color
        label.font = font
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    static func row(title: String, shortcut: String, highlighted: Bool, font: NSFont, inset: CGFloat) -> NSView {
        let row = NSView()
        row.wantsLayer = true
        row.layer?.cornerRadius = 6
        row.layer?.backgroundColor = highlighted ? raised.cgColor : nil
        let titleLabel = label(title, color: highlighted ? text : dim, font: font)
        let shortcutLabel = label(shortcut, color: dim, font: font)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        shortcutLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        row.addSubview(titleLabel)
        row.addSubview(shortcutLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: inset),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: shortcutLabel.leadingAnchor, constant: -8),
            shortcutLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -inset),
            shortcutLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])
        return row
    }
}
