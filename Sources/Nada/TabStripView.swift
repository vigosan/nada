import AppKit

final class TabStripView: NSView {
    var onSelect: (Int) -> Void = { _ in }
    private let stack = NSStackView()
    private var shown: (titles: [String], active: Int?) = ([], nil)

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.backgroundColor = Theme.bar.cgColor
        stack.distribution = .fillEqually
        stack.spacing = 2
        stack.edgeInsets = NSEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func clicked(_ recognizer: NSClickGestureRecognizer) {
        recognizer.view.flatMap(stack.arrangedSubviews.firstIndex).map(onSelect)
    }

    func update(titles: [String], active: Int?) {
        guard shown.titles != titles || shown.active != active else { return }
        shown = (titles, active)
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (index, title) in titles.enumerated() {
            let row = Theme.row(
                title: title,
                shortcut: index < 9 ? "⌘\(index + 1)" : "",
                highlighted: index == active,
                font: .systemFont(ofSize: 12),
                inset: 10
            )
            row.layer?.cornerRadius = 12
            row.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(clicked(_:))))
            stack.addArrangedSubview(row)
        }
    }
}
