import AppKit

final class PanesView: NSView {
    private var panes: [(view: NSView, frame: CGRect)] = []

    override var isFlipped: Bool {
        true
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = Theme.divider.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func restyle() {
        layer?.backgroundColor = Theme.divider.cgColor
    }

    func show(_ panes: [(view: NSView, frame: CGRect)]) {
        for view in subviews where !panes.contains(where: { $0.view === view }) {
            view.removeFromSuperview()
        }
        for pane in panes where pane.view.superview !== self {
            addSubview(pane.view)
        }
        self.panes = panes
        needsLayout = true
    }

    override func layout() {
        super.layout()
        for pane in panes {
            let dividerRight: CGFloat = pane.frame.maxX < 0.999 ? 1 : 0
            let dividerBottom: CGFloat = pane.frame.maxY < 0.999 ? 1 : 0
            pane.view.frame = CGRect(
                x: (pane.frame.minX * bounds.width).rounded(),
                y: (pane.frame.minY * bounds.height).rounded(),
                width: (pane.frame.width * bounds.width).rounded() - dividerRight,
                height: (pane.frame.height * bounds.height).rounded() - dividerBottom
            )
        }
    }
}
