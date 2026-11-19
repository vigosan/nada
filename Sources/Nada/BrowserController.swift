import AppKit
import NadaCore
import WebKit

enum ConfigFile {
    static let url = URL.homeDirectory.appending(path: ".config/nada/config")
}

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
    private var centeredPalette: [NSLayoutConstraint] = []
    private var cornerPalette: [NSLayoutConstraint] = []
    private var tabs = TabList<Tab>()
    private let modules: [BrowserModule]
    private var config: Config
    var onReloadConfig: () -> Void = {}
    var onNewWindow: (Bool) -> Void = { _ in }
    var onClose: () -> Void = {}
    let isPrivate: Bool
    private let restores: Bool
    private lazy var privateStore = WKWebsiteDataStore.nonPersistent()
    private var appearanceObservation: NSKeyValueObservation?
    private var mediaTimer: Timer?
    private enum Mode: Equatable {
        case commands
        case settings(SettingsSection?)
        case saveBookmark
        case bookmarks(String?)
        case downloads(Int?)
        case find
    }

    private var mode = Mode.commands
    private var lastFind = ""
    private var closedPages: [URL] = []
    private weak var announcedPane: Pane?
    private var extensions: WKWebExtensionController? {
        modules.lazy.compactMap { ($0 as? ExtensionsModule)?.controller }.first
    }
    var downloads = DownloadList()
    var downloadFiles: [Int: URL] = [:]
    var activeDownloads: [ObjectIdentifier: (id: Int, download: WKDownload, observation: NSKeyValueObservation)] = [:]
    var trustedHosts: Set<String> = []
    private let sessionFile = URL.applicationSupportDirectory.appending(path: "Nada/session.json")
    private let library: Library
    private var searchEngine: SearchEngine {
        get { UserDefaults.standard.string(forKey: "search.engine").flatMap(SearchEngine.init) ?? .duckDuckGo }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "search.engine") }
    }
    private var settings: [Setting] {
        [
            Setting(id: "search.engine", title: "Buscador", value: searchEngine.title),
            Setting(id: "theme", title: "Tema", value: Theme.name),
        ] + modules.flatMap(\.settings)
    }

    init(modules: [BrowserModule], config: Config, library: Library = Library(), isPrivate: Bool = false, restores: Bool = true) {
        self.modules = modules
        self.config = config
        self.library = library
        self.isPrivate = isPrivate
        self.restores = restores
        super.init()
        modules.compactMap { $0 as? ExtensionsModule }.forEach { $0.browser = self }
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.toolbar = NSToolbar()
        window.toolbarStyle = .unifiedCompact
        window.titlebarSeparatorStyle = .none
        window.backgroundColor = Theme.window
        window.appearance = NSAppearance(named: Theme.colors.isDark ? .darkAqua : .aqua)
        window.center()
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("Nada")
        strip.caption = isPrivate ? "Privada" : ""
        window.delegate = self

        let root = NSView()
        root.wantsLayer = true
        window.contentView = root
        palette.isHidden = true
        palette.itemsForQuery = { [unowned self] query in
            switch mode {
            case .settings(let section):
                return Palette.settingsItems(query: query, settings: settings, bindings: config.keyBindings, section: section)
            case .find: return Palette.findItems(query: query)
            case .bookmarks(let category): return Palette.bookmarkItems(query: query, bookmarks: library.bookmarks, category: category)
            case .downloads(let selected): return Palette.downloadItems(query: query, downloads: downloads, selected: selected)
            case .saveBookmark:
                guard let page = tabs.active?.focused?.webView.url else { return [] }
                return Palette.bookmarkSaveItems(query: query, bookmarks: library.bookmarks, page: page)
            case .commands: break
            }
            return Palette.items(
                query: query,
                tabTitles: tabs.tabs.map(\.title),
                activeTab: tabs.activeIndex,
                moduleCommands: self.modules.flatMap(\.commands),
                searchEngine: searchEngine,
                bindings: config.keyBindings,
                history: library.history,
                bookmarks: library.bookmarks
            )
        }
        palette.onClose = { [unowned self] in
            if case .settings(let section?) = mode {
                openPalette(mode: .settings(section.parent))
            } else if case .bookmarks(.some) = mode {
                openPalette(mode: .bookmarks(nil))
            } else if case .downloads(.some) = mode {
                openPalette(mode: .downloads(nil))
            } else {
                closePalette()
            }
        }
        palette.onDismiss = { [unowned self] in palette.isHidden = true }
        strip.onSelect = { [unowned self] index in run(.selectTab(index)) }
        palette.onRun = { [unowned self] action in
            if case .changeSetting(let id) = action {
                changeSetting(id)
                palette.reload()
                return
            }
            if case .find = action {
                run(action)
                return
            }
            if case .openSettingsSection(let section) = action {
                openPalette(mode: .settings(section))
                return
            }
            if case .openBookmarkCategory(let category) = action {
                openPalette(mode: .bookmarks(category))
                return
            }
            if case .download(let id) = action {
                openPalette(mode: .downloads(id))
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
        ])
        centeredPalette = [
            palette.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            palette.topAnchor.constraint(equalTo: root.topAnchor, constant: 120),
            palette.widthAnchor.constraint(equalToConstant: 560),
        ]
        cornerPalette = [
            palette.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -16),
            palette.topAnchor.constraint(equalTo: content.topAnchor, constant: 12),
            palette.widthAnchor.constraint(equalToConstant: 340),
        ]
        restoreSession()
        extensions?.didOpenWindow(self)
        extensions?.didFocusWindow(self)
        responderObservation = window.observe(\.firstResponder) { [weak self] _, _ in self?.followClickedPane() }
        appearanceObservation = NSApp.observe(\.effectiveAppearance) { [weak self] _, _ in self?.applyTheme() }
        mediaTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.checkMedia() }
    }

    func apply(_ config: Config) {
        self.config = config
        tabs.tabs.forEach { $0.layout.preservesZoom = config.preservesZoomOnNavigation }
        applyTheme()
    }

    private func applyTheme() {
        Theme.load(config)
        window.appearance = NSAppearance(named: Theme.colors.isDark ? .darkAqua : .aqua)
        window.backgroundColor = Theme.window
        progressBar.layer?.backgroundColor = Theme.accent.cgColor
        strip.restyle()
        container.restyle()
        palette.restyle()
        for pane in tabs.tabs.flatMap(\.panes.values) {
            pane.view.layer?.backgroundColor = Theme.window.cgColor
            pane.dim.layer?.backgroundColor = Theme.veil.cgColor
        }
        refresh()
    }

    private func whenModulesReady(_ action: @escaping () -> Void) {
        var remaining = modules.count
        guard remaining > 0 else { return action() }
        for module in modules {
            module.whenReady {
                remaining -= 1
                if remaining == 0 { action() }
            }
        }
    }

    func open(_ url: URL) {
        let blank = tabs.active?.focused.flatMap { $0.isBlank ? $0 : nil }
        let webView = (blank ?? addTab(configuration: WKWebViewConfiguration())).webView
        whenModulesReady { webView.load(URLRequest(url: url)) }
        palette.isHidden = true
        focusPage()
    }

    @discardableResult
    func openExtensionPage(_ url: URL?, configuration: WKWebViewConfiguration?) -> Pane {
        let pane = makePane(configuration: configuration ?? WKWebViewConfiguration(), extensionPage: configuration != nil)
        tabs.append(makeTab(pane))
        extensions?.didOpenTab(pane)
        showActiveTab()
        url.map { _ = pane.webView.load(URLRequest(url: $0)) }
        palette.isHidden = true
        focusPage()
        return pane
    }

    func openInBackground(_ request: URLRequest) {
        let pane = makePane(configuration: WKWebViewConfiguration())
        tabs.insertAfterActive(makeTab(pane))
        extensions?.didOpenTab(pane)
        pane.webView.load(request)
        refresh()
    }

    func pane(for webView: WKWebView) -> Pane? {
        tabs.tabs.flatMap(\.panes.values).first { $0.webView === webView }
    }

    var panesInOrder: [Pane] {
        tabs.tabs.flatMap { tab in tab.panes.sorted { $0.key < $1.key }.map(\.value) }
    }

    var focusedPane: Pane? {
        tabs.active?.focused
    }

    func activate(_ pane: Pane) {
        guard let index = tabs.tabs.firstIndex(where: { $0.panes.values.contains { $0 === pane } }),
              let id = tabs.tabs[index].panes.first(where: { $0.value === pane })?.key else { return }
        tabs.select(index)
        tabs.tabs[index].layout.focus(id)
        showActiveTab()
    }

    func close(_ pane: Pane) {
        guard let index = tabs.tabs.firstIndex(where: { $0.panes.values.contains { $0 === pane } }) else { return }
        let previous = tabs.activeIndex ?? index
        let count = tabs.tabs.count
        activate(pane)
        close()
        guard previous != index else { return }
        tabs.select(tabs.tabs.count < count && previous > index ? previous - 1 : previous)
        showActiveTab()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        modules.compactMap { $0 as? ExtensionsModule }.forEach { $0.browser = self }
        extensions?.didFocusWindow(self)
    }

    private func checkMedia() {
        for pane in panesInOrder where pane.pending == nil {
            pane.webView.requestMediaPlaybackState { [weak self, weak pane] state in
                guard let pane, pane.isPlaying != (state == .playing) else { return }
                pane.isPlaying = state == .playing
                self?.refresh()
            }
        }
    }

    func windowWillClose(_ notification: Notification) {
        mediaTimer?.invalidate()
        modules.compactMap { $0 as? ExtensionsModule }.forEach { $0.closed(self) }
        extensions?.didCloseWindow(self)
        onClose()
    }

    func saveState() {
        library.saveHistory()
        guard config.restoresWindows, !isPrivate else { return }
        Library.save(Session(pages: tabs.tabs.map(\.sessionPage), active: tabs.activeIndex ?? 0, closed: closedPages), to: sessionFile)
    }

    private func restoreSession() {
        let saved = try? JSONDecoder().decode(Session.self, from: Data(contentsOf: sessionFile))
        let session = config.restoresWindows && restores ? saved : nil
        closedPages = session?.closed ?? []
        for page in session?.tabs ?? [] {
            let pane = pendingPane(page)
            guard let split = page.split else {
                tabs.append(makeTab(pane))
                continue
            }
            let tab = Tab(layout: split.layout, panes: split.others.mapValues(pendingPane).merging([split.layout.focused: pane]) { $1 })
            tab.layout.preservesZoom = config.preservesZoomOnNavigation
            tabs.append(tab)
        }
        guard let session, !session.tabs.isEmpty else {
            addTab(configuration: WKWebViewConfiguration())
            openPalette()
            return
        }
        tabs.select(session.active)
        showActiveTab()
    }

    private func pendingPane(_ page: SessionPage) -> Pane {
        let pane = makePane(configuration: WKWebViewConfiguration())
        pane.pending = page
        extensions?.didOpenTab(pane)
        return pane
    }

    func run(_ action: PaletteAction) {
        switch action {
        case .newWindow(let isPrivate):
            onNewWindow(isPrivate)
        case .open(let url):
            tabs.active?.focused?.webView.load(URLRequest(url: url))
            focusPage()
        case .newTab:
            addTab(configuration: WKWebViewConfiguration())
            openPalette()
        case .closeTab:
            close()
        case .reload:
            guard let pane = tabs.active?.focused else { return }
            if let failed = pane.failedURL {
                pane.webView.load(URLRequest(url: failed))
            } else {
                pane.webView.reload()
            }
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
            openPalette(mode: .settings(nil))
        case .changeSetting(let id):
            changeSetting(id)
        case .togglePalette:
            if palette.isHidden {
                openPalette()
            } else {
                closePalette()
            }
        case .openLocation:
            openPalette(prefill: tabs.active?.focused?.address?.absoluteString ?? "")
        case .split(let axis):
            split(axis)
        case .focusPane(let direction):
            tabs.active?.layout.moveFocus(direction)
            showActiveTab()
        case .cyclePane(let forward):
            if forward {
                tabs.active?.layout.focusNext()
            } else {
                tabs.active?.layout.focusPrevious()
            }
            showActiveTab()
        case .resizePane(let direction):
            tabs.active?.layout.resize(direction)
            showActiveTab()
        case .zoomPane:
            tabs.active?.layout.toggleZoom()
            showActiveTab()
        case .toggleFullscreen:
            window.toggleFullScreen(nil)
        case .nextTab:
            tabs.selectNext()
            showActiveTab()
        case .previousTab:
            tabs.selectPrevious()
            showActiveTab()
        case .moveTab(let forward):
            guard let previous = tabs.moveActive(by: forward ? 1 : -1) else { return }
            tabs.active?.focused.map { extensions?.didMoveTab($0, from: previous, in: self) }
            showActiveTab()
        case .duplicateTab:
            guard let address = tabs.active?.focused?.address else { return }
            let pane = makePane(configuration: WKWebViewConfiguration())
            tabs.insertAfterActive(makeTab(pane))
            tabs.selectNext()
            extensions?.didOpenTab(pane)
            pane.webView.load(URLRequest(url: address))
            showActiveTab()
        case .equalizePanes:
            tabs.active?.layout.equalize()
            showActiveTab()
        case .reopenTab:
            guard let url = closedPages.popLast() else { return }
            addTab(configuration: WKWebViewConfiguration()).webView.load(URLRequest(url: url))
        case .zoomIn:
            zoomPage { $0 * 1.1 }
        case .zoomOut:
            zoomPage { $0 / 1.1 }
        case .resetZoom:
            zoomPage { _ in 1 }
        case .startFind:
            openPalette(prefill: lastFind, mode: .find)
        case .findNext:
            run(lastFind.isEmpty ? .startFind : .find(lastFind, backwards: false))
        case .findPrevious:
            run(lastFind.isEmpty ? .startFind : .find(lastFind, backwards: true))
        case .editKeyBindings:
            if !FileManager.default.fileExists(atPath: ConfigFile.url.path) {
                try? FileManager.default.createDirectory(at: ConfigFile.url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try? Config.template.write(to: ConfigFile.url, atomically: true, encoding: .utf8)
            }
            NSWorkspace.shared.open(ConfigFile.url)
        case .openSettingsSection(let section):
            openPalette(mode: .settings(section))
        case .bookmarkPage:
            guard tabs.active?.focused?.isBlank == false else { return }
            openPalette(mode: .saveBookmark)
        case .openBookmarks:
            openPalette(mode: .bookmarks(nil))
        case .openBookmarkCategory(let category):
            openPalette(mode: .bookmarks(category))
        case .saveBookmark(let category):
            guard let pane = tabs.active?.focused, let url = pane.webView.url else { return }
            library.bookmarks.save(url: url, title: pane.title, category: category)
            library.saveBookmarks()
        case .removeBookmark:
            guard let url = tabs.active?.focused?.webView.url else { return }
            library.bookmarks.remove(url: url)
            library.saveBookmarks()
        case .openDownloads:
            openPalette(mode: .downloads(nil))
        case .download(let id):
            openPalette(mode: .downloads(id))
        case .openDownloadedFile(let id):
            downloadFiles[id].map { _ = NSWorkspace.shared.open($0) }
        case .revealDownload(let id):
            downloadFiles[id].map { NSWorkspace.shared.activateFileViewerSelecting([$0]) }
        case .cancelDownload(let id):
            cancelDownload(id)
        case .clearDownloads:
            downloads.clear()
            downloadFiles = downloadFiles.filter { id, _ in downloads.items.contains { $0.id == id } }
        case .reloadConfig:
            onReloadConfig()
        case .clearHistory:
            library.history.clear()
            library.saveHistory()
        case .makeDefaultBrowser:
            NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpenURLsWithScheme: "http") { [weak self] error in
                guard let error else { return }
                DispatchQueue.main.async {
                    self?.ask("No se pudo cambiar el navegador por defecto", detail: error.localizedDescription, buttons: ["Aceptar"]) { _ in }
                }
            }
        case .printPage:
            guard let webView = tabs.active?.focused?.webView else { return }
            let operation = webView.printOperation(with: NSPrintInfo.shared)
            operation.view?.frame = webView.bounds
            operation.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)
        case .pauseMedia:
            panesInOrder.forEach { $0.webView.pauseAllMediaPlayback() }
        case .clearSiteData:
            ask(
                "¿Borrar cookies y datos de sitios?",
                detail: "Se cerrarán todas tus sesiones y se borrará lo que los sitios han guardado en este Mac.",
                buttons: ["Borrar", "Cancelar"]
            ) { response in
                guard response == .alertFirstButtonReturn else { return }
                WKWebsiteDataStore.default().removeData(
                    ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                    modifiedSince: .distantPast
                ) {}
            }
        case .find(let text, let backwards):
            lastFind = text
            let configuration = WKFindConfiguration()
            configuration.backwards = backwards
            tabs.active?.focused?.webView.find(text, configuration: configuration) { _ in }
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
        } else if id == "theme" {
            run(.editKeyBindings)
        } else {
            modules.first { $0.settings.contains { $0.id == id } }?.changeSetting(id)
        }
    }

    private func openPalette(prefill: String = "", mode: Mode = .commands) {
        self.mode = mode
        NSLayoutConstraint.deactivate(mode == .find ? centeredPalette : cornerPalette)
        NSLayoutConstraint.activate(mode == .find ? cornerPalette : centeredPalette)
        let placeholder = switch mode {
        case .commands: "URL, búsqueda, pestaña u orden…"
        case .find: "Buscar en la página"
        case .settings(let section): section?.path ?? "Ajustes"
        case .saveBookmark: "Guardar en marcadores: elige o escribe una categoría"
        case .bookmarks(let category): category.map { "Marcadores › \($0)" } ?? "Marcadores"
        case .downloads(let selected):
            downloads.items.first { $0.id == selected }.map { "Descargas › \($0.name)" }
                ?? (downloads.items.isEmpty ? "No hay descargas" : "Descargas")
        }
        palette.open(prefill: prefill, placeholder: placeholder)
    }

    private func zoomPage(_ change: (Double) -> Double) {
        guard let webView = tabs.active?.focused?.webView else { return }
        webView.pageZoom = min(3, max(0.5, change(webView.pageZoom)))
        guard !isPrivate else { return }
        library.zoom.set(webView.pageZoom, for: webView.url)
        library.saveZoom()
    }

    func restoreZoom(of webView: WKWebView) {
        webView.pageZoom = library.zoom.factor(for: webView.url)
    }

    private func split(_ axis: SplitAxis) {
        guard let tab = tabs.active else { return }
        let pane = makePane(configuration: WKWebViewConfiguration())
        tab.panes[tab.layout.split(axis)] = pane
        extensions?.didOpenTab(pane)
        showActiveTab()
        openPalette()
    }

    private func close() {
        guard let tab = tabs.active else { return }
        let closing = tab.layout.focused
        tab.focused?.address.map { closedPages.append($0) }
        tab.focused.map { extensions?.didCloseTab($0, windowIsClosing: false) }
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

    func webViewDidClose(_ webView: WKWebView) {
        pane(for: webView).map(close)
    }

    @discardableResult
    private func addTab(configuration: WKWebViewConfiguration) -> Pane {
        let pane = makePane(configuration: configuration)
        tabs.append(makeTab(pane))
        extensions?.didOpenTab(pane)
        showActiveTab()
        return pane
    }

    private func makeTab(_ pane: Pane) -> Tab {
        let tab = Tab(pane: pane)
        tab.layout.preservesZoom = config.preservesZoomOnNavigation
        return tab
    }

    private func makePane(configuration: WKWebViewConfiguration, extensionPage: Bool = false) -> Pane {
        if !extensionPage { modules.forEach { $0.configure(configuration) } }
        if isPrivate { configuration.websiteDataStore = privateStore }
        let pane = Pane(configuration: configuration, extensionPage: extensionPage)
        pane.browser = self
        pane.webView.uiDelegate = self
        pane.webView.navigationDelegate = self
        pane.observations = [
            pane.webView.observe(\.title) { [weak self, weak pane] _, _ in
                pane.map { self?.record($0) }
                pane.map { self?.extensions?.didChangeTabProperties(.title, for: $0) }
                self?.refresh()
            },
            pane.webView.observe(\.url) { [weak self, weak pane] _, _ in
                pane.map { self?.extensions?.didChangeTabProperties(.URL, for: $0) }
                self?.refresh()
            },
            pane.webView.observe(\.estimatedProgress) { [weak self] _, _ in self?.refresh() },
            pane.webView.observe(\.isLoading) { [weak self, weak pane] _, _ in
                pane.map { self?.extensions?.didChangeTabProperties(.loading, for: $0) }
                self?.refresh()
            },
        ]
        return pane
    }

    private func record(_ pane: Pane) {
        guard !isPrivate, let url = pane.webView.url, ["http", "https"].contains(url.scheme),
              let title = pane.webView.title, !title.isEmpty else { return }
        library.history.record(url: url, title: title, at: Date(), newVisit: pane.recordedURL != url)
        pane.recordedURL = url
        library.saveHistorySoon()
    }

    private func showActiveTab() {
        let tab = tabs.active
        for pane in tab?.panes.values ?? [:].values {
            guard pane.pending != nil else { continue }
            whenModulesReady { [weak pane] in
                guard let pane, let page = pane.pending else { return }
                pane.pending = nil
                if let state = page.state {
                    pane.webView.interactionState = state
                } else {
                    pane.webView.load(URLRequest(url: page.url))
                }
            }
        }
        container.show(tab?.layout.frames.compactMap { id, frame in
            tab?.panes[id].map { (view: $0.view, frame: frame) }
        } ?? [])
        refresh()
        if palette.isHidden { focusPage() }
    }

    private func refresh() {
        let labels = tabs.tabs.enumerated().map { index, tab in
            TabLabel.text(title: tab.title, address: tab.focused?.address, active: index == tabs.activeIndex, playing: tab.isPlaying)
        }
        strip.update(titles: labels, active: tabs.activeIndex)
        if let tab = tabs.active {
            for (id, pane) in tab.panes {
                pane.webView.isHidden = pane.isBlank
                let focused = id == tab.layout.focused
                pane.dim.isHidden = tab.panes.count == 1 || focused
                pane.view.layer?.borderColor = Theme.accent.withAlphaComponent(0.5).cgColor
                pane.view.layer?.borderWidth = tab.panes.count > 1 && focused ? 1 : 0
            }
        }
        refreshProgress()
        if let pane = focusedPane, pane !== announcedPane {
            extensions?.didActivateTab(pane, previousActiveTab: announcedPane)
            announcedPane = pane
        }
    }

    func downloadsChanged() {
        refreshProgress()
        if !palette.isHidden, case .downloads = mode { palette.reload() }
    }

    func refreshProgress() {
        let webView = tabs.active?.focused?.webView
        let loading = webView?.isLoading == true ? webView?.estimatedProgress : nil
        let progress = loading ?? downloads.progress.map { max(0.03, $0) }
        progressBar.isHidden = progress == nil
        progressWidth.constant = container.bounds.width * (progress ?? 0)
    }

    private func closePalette() {
        palette.isHidden = true
        focusPage()
    }

    private func focusPage() {
        window.makeFirstResponder(tabs.active?.focused.flatMap { $0.isBlank ? nil : $0.webView })
    }
}
