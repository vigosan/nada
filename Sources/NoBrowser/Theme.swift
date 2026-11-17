import AppKit

enum Theme {
    static let window = NSColor(srgbRed: 0.106, green: 0.110, blue: 0.153, alpha: 1)
    static let bar = NSColor(srgbRed: 0.133, green: 0.137, blue: 0.184, alpha: 1)
    static let raised = NSColor(srgbRed: 0.169, green: 0.176, blue: 0.231, alpha: 1)
    static let text = NSColor(srgbRed: 0.804, green: 0.816, blue: 0.902, alpha: 1)
    static let dim = NSColor(srgbRed: 0.490, green: 0.506, blue: 0.612, alpha: 1)

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
