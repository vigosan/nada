import AppKit
import NadaCore

final class PaletteView: NSVisualEffectView, NSTextFieldDelegate {
    var itemsForQuery: (String) -> [PaletteItem] = { _ in [] }
    var onRun: (PaletteAction) -> Void = { _ in }
    var onClose: () -> Void = {}
    var onDismiss: () -> Void = {}

    private let field = NSTextField()
    private let rows = NSStackView()
    private var items: [PaletteItem] = []
    private var selected = 0

    override init(frame: NSRect) {
        super.init(frame: frame)
        material = .menu
        blendingMode = .withinWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = Theme.raised.cgColor

        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        field.textColor = Theme.text
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false

        rows.orientation = .vertical
        rows.spacing = 2
        rows.alignment = .leading
        rows.translatesAutoresizingMaskIntoConstraints = false

        addSubview(field)
        addSubview(rows)
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            field.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            field.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            rows.topAnchor.constraint(equalTo: field.bottomAnchor, constant: 12),
            rows.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            rows.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            rows.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func restyle() {
        layer?.borderColor = Theme.raised.cgColor
        field.textColor = Theme.text
        render()
    }

    func open(prefill: String, placeholder: String) {
        field.placeholderString = placeholder
        field.stringValue = prefill
        selected = 0
        reload()
        isHidden = false
        window?.makeFirstResponder(field)
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !isHidden, window?.firstResponder !== field.currentEditor() else { return }
            onDismiss()
        }
    }

    func controlTextDidChange(_ notification: Notification) {
        selected = 0
        reload()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.moveDown(_:)):
            move(by: 1)
        case #selector(NSResponder.moveUp(_:)):
            move(by: -1)
        case #selector(NSResponder.insertNewline(_:)):
            if items.indices.contains(selected) { onRun(items[selected].action) }
        case #selector(NSResponder.cancelOperation(_:)):
            onClose()
        default:
            return false
        }
        return true
    }

    private func move(by step: Int) {
        guard !items.isEmpty else { return }
        selected = (selected + step + items.count) % items.count
        render()
    }

    func reload() {
        items = itemsForQuery(field.stringValue)
        render()
    }

    private func render() {
        rows.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for index in Palette.window(selected: selected, count: items.count, size: 9) {
            let item = items[index]
            let row = Theme.row(
                title: item.title,
                shortcut: item.shortcut,
                highlighted: index == selected,
                font: .monospacedSystemFont(ofSize: 13, weight: .regular),
                inset: 10
            )
            row.translatesAutoresizingMaskIntoConstraints = false
            rows.addArrangedSubview(row)
            NSLayoutConstraint.activate([
                row.heightAnchor.constraint(equalToConstant: 30),
                row.widthAnchor.constraint(equalTo: rows.widthAnchor),
            ])
        }
    }
}
