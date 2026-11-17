import AppKit
import NoBrowserCore
import WebKit

final class BrowserController: NSObject, WKUIDelegate, NSWindowDelegate {
    let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
        styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
        backing: .buffered,
        defer: false
    )
    private let strip = TabStripView()
    private let container = PanesView()
    private var responderObservation: NSKeyValueObservation?
    private let palette = PaletteView()
    private let progressBar = NSView()
    private lazy var progressWidth = progressBar.widthAnchor.constraint(equalToConstant: 0)
    private var tabs = TabList<Tab>()
    private let modules: [BrowserModule]
    private let bindings: KeyBindings
    private var showingSettings = false
    private var searchEngine: SearchEngine {
        get { UserDefaults.standard.string(forKey: "search.engine").flatMap(SearchEngine.init) ?? .duckDuckGo }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "search.engine") }
    }
    private var settings: [Setting] {
        [Setting(id: "search.engine", title: "Buscador", value: searchEngine.title)] + modules.flatMap(\.settings)
    }

    init(modules: [BrowserModule], bindings: KeyBindings) {
        self.modules = modules
        self.bindings = bindings
        super.init()
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.toolbar = NSToolbar()
        window.toolbarStyle = .unifiedCompact
        window.titlebarSeparatorStyle = .none
        window.backgroundColor = Theme.window
        window.appearance = NSAppearance(named: .darkAqua)
        window.center()
        window.setFrameAutosaveName("NoBrowser")
        window.delegate = self

        let root = NSView()
        root.wantsLayer = true
        window.contentView = root
        palette.isHidden = true
        palette.itemsForQuery = { [unowned self] query in
            if showingSettings { return Palette.settingsItems(query: query, settings: settings) }
            return Palette.items(
                query: query,
                tabTitles: tabs.tabs.map(\.title),
                moduleCommands: self.modules.flatMap(\.commands),
                searchEngine: searchEngine,
                bindings: self.bindings
            )
        }
        palette.onClose = { [unowned self] in closePalette() }
        palette.onRun = { [unowned self] action in
            if case .changeSetting(let id) = action {
                changeSetting(id)
                palette.reload()
                return
            }
            closePalette()
            run(action)
        }
        progressBar.wantsLayer = true
        progressBar.layer?.backgroundColor = Theme.accent.cgColor
        for view in [strip, container, progressBar, palette] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        let titlebar = NSLayoutGuide()
        root.addLayoutGuide(titlebar)
        let content = window.contentLayoutGuide as! NSLayoutGuide
        NSLayoutConstraint.activate([
            titlebar.topAnchor.constraint(equalTo: root.topAnchor),
            titlebar.bottomAnchor.constraint(equalTo: content.topAnchor),
            strip.centerYAnchor.constraint(equalTo: titlebar.centerYAnchor),
            strip.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 78),
            strip.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -8),
            strip.heightAnchor.constraint(equalToConstant: 28),
            container.topAnchor.constraint(equalTo: content.topAnchor),
            container.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            progressBar.topAnchor.constraint(equalTo: container.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 2),
            progressWidth,
            palette.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            palette.topAnchor.constraint(equalTo: root.topAnchor, constant: 120),
            palette.widthAnchor.constraint(equalToConstant: 560),
        ])
        addTab(configuration: WKWebViewConfiguration())
        responderObservation = window.observe(\.firstResponder) { [weak self] _, _ in self?.followClickedPane() }
    }

    func run(_ action: PaletteAction) {
        switch action {
        case .open(let url):
            tabs.active?.focused?.webView.load(URLRequest(url: url))
            focusPage()
        case .newTab:
            addTab(configuration: WKWebViewConfiguration())
            openPalette()
        case .closeTab:
            close()
        case .reload:
            tabs.active?.focused?.webView.reload()
        case .back:
            tabs.active?.focused?.webView.goBack()
        case .forward:
            tabs.active?.focused?.webView.goForward()
        case .toggleDevTools:
            toggleDevTools()
        case .selectTab(let index):
            tabs.select(index)
            showActiveTab()
        case .module(let id):
            modules.first { $0.commands.contains { $0.id == id } }?.run(id)
        case .openSettings:
            openPalette(settings: true)
        case .changeSetting(let id):
            changeSetting(id)
        case .togglePalette:
            if palette.isHidden {
                openPalette()
            } else {
                closePalette()
            }
        case .openLocation:
            openPalette(prefill: tabs.active?.focused?.webView.url?.absoluteString ?? "")
        case .split(let axis):
            split(axis)
        case .focusPane(let direction):
            tabs.active?.layout.moveFocus(direction)
            showActiveTab()
        case .resizePane(let direction):
            tabs.active?.layout.resize(direction)
            showActiveTab()
        case .zoomPane:
            tabs.active?.layout.toggleZoom()
            showActiveTab()
        case .toggleFullscreen:
            window.toggleFullScreen(nil)
        }
    }

    func windowWillEnterFullScreen(_ notification: Notification) {
        strip.isHidden = true
    }

    func windowWillExitFullScreen(_ notification: Notification) {
        strip.isHidden = false
    }

    private func changeSetting(_ id: String) {
        if id == "search.engine" {
            searchEngine = searchEngine.next
        } else {
            modules.first { $0.settings.contains { $0.id == id } }?.changeSetting(id)
        }
    }

    private func openPalette(prefill: String = "", settings: Bool = false) {
        showingSettings = settings
        palette.open(prefill: prefill, placeholder: settings ? "Ajustes" : "URL, búsqueda, pestaña u orden…")
    }

    private func split(_ axis: SplitAxis) {
        guard let tab = tabs.active else { return }
        tab.panes[tab.layout.split(axis)] = makePane(configuration: WKWebViewConfiguration())
        showActiveTab()
        openPalette()
    }

    private func close() {
        guard let tab = tabs.active else { return }
        let closing = tab.layout.focused
        if tab.layout.closeFocused() {
            tab.panes.removeValue(forKey: closing)
        } else {
            _ = tabs.closeActive()
            if tabs.active == nil { addTab(configuration: WKWebViewConfiguration()) }
        }
        showActiveTab()
    }

    private func toggleDevTools() {
        let accessor = Selector(("_inspector"))
        guard let webView = tabs.active?.focused?.webView, webView.responds(to: accessor),
              let inspector = webView.perform(accessor)?.takeUnretainedValue() as? NSObject else { return }
        let visible = inspector.value(forKey: "isVisible") as? Bool ?? false
        inspector.perform(Selector((visible ? "close" : "show")))
    }

    private func followClickedPane() {
        guard let tab = tabs.active, let responder = window.firstResponder as? NSView,
              let clicked = tab.panes.first(where: { responder.isDescendant(of: $0.value.webView) })?.key,
              clicked != tab.layout.focused else { return }
        tab.layout.focus(clicked)
        refresh()
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
    private func addTab(configuration: WKWebViewConfiguration) -> Pane {
        let pane = makePane(configuration: configuration)
        tabs.append(Tab(pane: pane))
        showActiveTab()
        return pane
    }

    private func makePane(configuration: WKWebViewConfiguration) -> Pane {
        modules.forEach { $0.configure(configuration) }
        let pane = Pane(configuration: configuration)
        pane.webView.uiDelegate = self
        pane.observations = [
            pane.webView.observe(\.title) { [weak self] _, _ in self?.refresh() },
            pane.webView.observe(\.url) { [weak self] _, _ in self?.refresh() },
            pane.webView.observe(\.estimatedProgress) { [weak self] _, _ in self?.refresh() },
            pane.webView.observe(\.isLoading) { [weak self] _, _ in self?.refresh() },
        ]
        return pane
    }

    private func showActiveTab() {
        let tab = tabs.active
        container.show(tab?.layout.frames.compactMap { id, frame in
            tab?.panes[id].map { (view: $0.view, frame: frame) }
        } ?? [])
        refresh()
        if palette.isHidden { focusPage() }
    }

    private func refresh() {
        strip.update(titles: tabs.tabs.map(\.title), active: tabs.activeIndex)
        if let tab = tabs.active {
            for (id, pane) in tab.panes {
                pane.webView.isHidden = pane.isBlank
                pane.view.alphaValue = tab.panes.count == 1 || id == tab.layout.focused ? 1 : 0.6
            }
        }
        let webView = tabs.active?.focused?.webView
        progressBar.isHidden = webView?.isLoading != true
        progressWidth.animator().constant = container.bounds.width * (webView?.estimatedProgress ?? 0)
    }

    private func closePalette() {
        palette.isHidden = true
        focusPage()
    }

    private func focusPage() {
        window.makeFirstResponder(tabs.active?.focused.flatMap { $0.isBlank ? nil : $0.webView })
    }
}
