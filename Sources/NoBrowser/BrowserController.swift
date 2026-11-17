import AppKit
import NoBrowserCore
import WebKit

final class Tab {
    let webView: WKWebView
    var observations: [NSKeyValueObservation] = []

    init(configuration: WKWebViewConfiguration) {
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        configuration.applicationNameForUserAgent = "Version/26.0 Safari/605.1.15"
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isInspectable = true
        webView.translatesAutoresizingMaskIntoConstraints = false
    }

    var isBlank: Bool {
        webView.url == nil
    }

    var title: String {
        if let title = webView.title, !title.isEmpty { return title }
        return webView.url?.host() ?? "Pestaña nueva"
    }
}

final class BrowserController: NSObject, WKUIDelegate {
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
        styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
        backing: .buffered,
        defer: false
    )
    private let strip = TabStripView()
    private let container = NSView()
    private let palette = PaletteView()
    private var tabs = TabList<Tab>()
    private let modules: [BrowserModule]

    init(modules: [BrowserModule]) {
        self.modules = modules
        super.init()
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = Theme.window
        window.appearance = NSAppearance(named: .darkAqua)
        window.center()
        window.setFrameAutosaveName("NoBrowser")

        let root = NSView()
        root.wantsLayer = true
        window.contentView = root
        palette.isHidden = true
        palette.itemsForQuery = { [unowned self] query in
            Palette.items(
                query: query,
                tabTitles: tabs.tabs.map(\.title),
                moduleCommands: self.modules.flatMap(\.commands)
            )
        }
        palette.onClose = { [unowned self] in closePalette() }
        palette.onRun = { [unowned self] action in
            closePalette()
            run(action)
        }
        for view in [strip, container, palette] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            strip.topAnchor.constraint(equalTo: root.topAnchor, constant: 6),
            strip.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 78),
            strip.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
            strip.heightAnchor.constraint(equalToConstant: 28),
            container.topAnchor.constraint(equalTo: strip.bottomAnchor, constant: 6),
            container.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            palette.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            palette.topAnchor.constraint(equalTo: root.topAnchor, constant: 120),
            palette.widthAnchor.constraint(equalToConstant: 560),
        ])
        addTab(configuration: WKWebViewConfiguration())
    }

    func run(_ action: PaletteAction) {
        switch action {
        case .open(let url):
            tabs.active?.webView.load(URLRequest(url: url))
            focusPage()
        case .newTab:
            newTab(nil)
        case .closeTab:
            closeTab(nil)
        case .reload:
            tabs.active?.webView.reload()
        case .back:
            tabs.active?.webView.goBack()
        case .forward:
            tabs.active?.webView.goForward()
        case .toggleDevTools:
            toggleDevTools(nil)
        case .selectTab(let index):
            tabs.select(index)
            showActiveTab()
        case .module(let id):
            modules.first { $0.commands.contains { $0.id == id } }?.run(id)
        }
    }

    @objc func newTab(_ sender: Any?) {
        addTab(configuration: WKWebViewConfiguration())
        palette.open(prefill: "")
    }

    @objc func closeTab(_ sender: Any?) {
        tabs.closeActive()?.webView.removeFromSuperview()
        if tabs.active == nil {
            addTab(configuration: WKWebViewConfiguration())
        } else {
            showActiveTab()
        }
    }

    @objc func togglePalette(_ sender: Any?) {
        if palette.isHidden {
            palette.open(prefill: "")
        } else {
            closePalette()
        }
    }

    @objc func openLocation(_ sender: Any?) {
        palette.open(prefill: tabs.active?.webView.url?.absoluteString ?? "")
    }

    @objc func reload(_ sender: Any?) {
        run(.reload)
    }

    @objc func goBack(_ sender: Any?) {
        run(.back)
    }

    @objc func goForward(_ sender: Any?) {
        run(.forward)
    }

    @objc func selectTab(_ sender: NSMenuItem) {
        run(.selectTab(sender.tag))
    }

    @objc func toggleDevTools(_ sender: Any?) {
        let accessor = Selector(("_inspector"))
        guard let webView = tabs.active?.webView, webView.responds(to: accessor),
              let inspector = webView.perform(accessor)?.takeUnretainedValue() as? NSObject else { return }
        let visible = inspector.value(forKey: "isVisible") as? Bool ?? false
        inspector.perform(Selector((visible ? "close" : "show")))
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        addTab(configuration: configuration).webView
    }

    @discardableResult
    private func addTab(configuration: WKWebViewConfiguration) -> Tab {
        modules.forEach { $0.configure(configuration) }
        let tab = Tab(configuration: configuration)
        tab.webView.uiDelegate = self
        tab.observations = [
            tab.webView.observe(\.title) { [weak self] _, _ in self?.refresh() },
            tab.webView.observe(\.url) { [weak self] _, _ in self?.refresh() },
        ]
        tabs.append(tab)
        showActiveTab()
        return tab
    }

    private func showActiveTab() {
        container.subviews.forEach { $0.removeFromSuperview() }
        if let webView = tabs.active?.webView {
            container.addSubview(webView)
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: container.topAnchor),
                webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            ])
        }
        refresh()
        if palette.isHidden { focusPage() }
    }

    private func refresh() {
        strip.update(titles: tabs.tabs.map(\.title), active: tabs.activeIndex)
        tabs.active.map { $0.webView.isHidden = $0.isBlank }
    }

    private func closePalette() {
        palette.isHidden = true
        focusPage()
    }

    private func focusPage() {
        window.makeFirstResponder(tabs.active.flatMap { $0.isBlank ? nil : $0.webView })
    }
}
