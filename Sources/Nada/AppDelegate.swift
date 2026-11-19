import AppKit
import NadaCore
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var browsers: [BrowserController] = []
    private let library = Library()
    private lazy var modules: [BrowserModule] = [AdBlockModule(), VimKeysModule(), ExtensionsModule()]
    private var browser: BrowserController? {
        browsers.first { $0.window.isKeyWindow } ?? browsers.first { $0.window.isMainWindow } ?? browsers.last
    }
    private var menuActions: [PaletteAction] = []
    private let updater = Bundle.main.bundleIdentifier.map { _ in
        SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }

    private let systemItems: [String: (title: String, action: Selector, key: String, modifiers: NSEvent.ModifierFlags, symbol: String)] = [
        "about": ("Acerca de Nada", #selector(NSApplication.orderFrontStandardAboutPanel(_:)), "", [], "info.circle"),
        "hide": ("Ocultar Nada", #selector(NSApplication.hide(_:)), "h", .command, "eye.slash"),
        "hideOthers": ("Ocultar otros", #selector(NSApplication.hideOtherApplications(_:)), "h", [.command, .option], "eye.slash"),
        "showAll": ("Mostrar todo", #selector(NSApplication.unhideAllApplications(_:)), "", [], "eye"),
        "quit": ("Salir de Nada", #selector(NSApplication.terminate(_:)), "q", .command, "power"),
        "undo": ("Deshacer", Selector(("undo:")), "z", .command, "arrow.uturn.backward"),
        "redo": ("Rehacer", Selector(("redo:")), "z", [.command, .shift], "arrow.uturn.forward"),
        "cut": ("Cortar", #selector(NSText.cut(_:)), "x", .command, "scissors"),
        "copy": ("Copiar", #selector(NSText.copy(_:)), "c", .command, "document.on.document"),
        "paste": ("Pegar", #selector(NSText.paste(_:)), "v", .command, "document.on.clipboard"),
        "selectAll": ("Seleccionar todo", #selector(NSText.selectAll(_:)), "a", .command, "character.textbox"),
        "minimize": ("Minimizar", #selector(NSWindow.performMiniaturize(_:)), "m", .command, "minus.rectangle"),
        "zoom": ("Zoom", #selector(NSWindow.performZoom(_:)), "", [], "arrow.up.left.and.arrow.down.right.rectangle"),
        "updates": ("Buscar actualizaciones…", #selector(SPUStandardUpdaterController.checkForUpdates(_:)), "", [], "arrow.down.circle"),
        "support": ("Soporte de Nada", #selector(openSupport(_:)), "", [], "questionmark.circle"),
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        let config = loadConfig()
        Theme.load(config)
        let browser = openWindow(config, isPrivate: false, restores: true)
        NSApp.mainMenu = mainMenu(config.keyBindings)
        if config.startsMaximized { browser.window.zoom(nil) }
        if config.startsFullscreen { browser.window.toggleFullScreen(nil) }
        NSApp.activate()
    }

    @discardableResult
    private func openWindow(_ config: Config, isPrivate: Bool, restores: Bool) -> BrowserController {
        let browser = BrowserController(
            modules: isPrivate ? modules.filter { !($0 is ExtensionsModule) } : modules,
            config: config,
            library: library,
            isPrivate: isPrivate,
            restores: restores
        )
        browser.onReloadConfig = { [weak self] in self?.reloadConfig() }
        browser.onNewWindow = { [weak self] isPrivate in
            guard let self else { return }
            openWindow(loadConfig(), isPrivate: isPrivate, restores: false)
        }
        browser.onClose = { [weak self, unowned browser] in
            guard let self, browsers.count > 1 else { return }
            browser.saveState()
            browsers.removeAll { $0 === browser }
        }
        if let front = self.browser {
            browser.window.setFrameTopLeftPoint(front.window.cascadeTopLeft(from: NSPoint(x: front.window.frame.minX, y: front.window.frame.maxY)))
        }
        browsers.append(browser)
        browser.window.makeKeyAndOrderFront(nil)
        return browser
    }

    private func loadConfig() -> Config {
        let folder = ConfigFile.url.deletingLastPathComponent()
        let config = Config(text: (try? String(contentsOf: ConfigFile.url, encoding: .utf8)) ?? "") { path in
            let file = path.hasPrefix("/") ? URL(fileURLWithPath: path) : folder.appending(path: path)
            return try? String(contentsOf: file, encoding: .utf8)
        }
        config.errors.forEach { NSLog("%@ %@", ConfigFile.url.path, $0) }
        return config
    }

    private func reloadConfig() {
        let config = loadConfig()
        menuActions = []
        NSApp.mainMenu = mainMenu(config.keyBindings)
        browsers.forEach { $0.apply(config) }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        let target = browser.flatMap { $0.isPrivate ? nil : $0 } ?? browsers.last { !$0.isPrivate } ?? browser
        urls.forEach { target?.open($0) }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let busy = browsers.filter { $0.downloads.running > 0 }
        guard let first = busy.first else { return .terminateNow }
        first.confirmLeavingDownloads(count: busy.map(\.downloads.running).reduce(0, +)) { leaving in
            if leaving { busy.forEach { $0.cancelDownloads() } }
            sender.reply(toApplicationShouldTerminate: leaving)
        }
        return .terminateLater
    }

    func applicationWillTerminate(_ notification: Notification) {
        (browsers.last { !$0.isPrivate } ?? browser)?.saveState()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc private func openSupport(_ sender: Any?) {
        URL(string: "https://nada.vicent.io/es/soporte").map { browser?.open($0) }
    }

    @objc private func runMenuItem(_ sender: NSMenuItem) {
        let action = menuActions[sender.tag]
        if [.back, .forward].contains(action), let editor = browser?.window.firstResponder as? NSTextView, let event = NSApp.currentEvent {
            editor.keyDown(with: event)
            return
        }
        if [.back, .forward].contains(action), let browser, let event = NSApp.currentEvent, event.type == .keyDown,
           let webView = browser.focusedPane?.webView, (browser.window.firstResponder as? NSView)?.isDescendant(of: webView) == true {
            webView.evaluateJavaScript(PageFocus.isTyping) { typing, _ in
                if typing as? Bool == true {
                    webView.keyDown(with: event)
                } else {
                    browser.run(action)
                }
            }
            return
        }
        browser?.run(action)
    }

    private func mainMenu(_ bindings: KeyBindings) -> NSMenu {
        let main = NSMenu()
        for section in MenuLayout.menus {
            let item = NSMenuItem()
            item.submenu = menu(section.title, section.entries, bindings)
            main.addItem(item)
            if section.title == "Ventana" { NSApp.windowsMenu = item.submenu }
            if section.title == "Ayuda" { NSApp.helpMenu = item.submenu }
        }
        return main
    }

    private func menu(_ title: String, _ entries: [MenuEntry], _ bindings: KeyBindings) -> NSMenu {
        let menu = NSMenu(title: title)
        for entry in entries {
            switch entry {
            case .separator:
                menu.addItem(.separator())
            case .system(let id):
                guard let system = systemItems[id] else { continue }
                let item = menu.addItem(withTitle: system.title, action: system.action, keyEquivalent: system.key)
                item.keyEquivalentModifierMask = system.modifiers
                item.image = NSImage(systemSymbolName: system.symbol, accessibilityDescription: nil)
                if id == "support" { item.target = self }
                if id == "updates" { item.target = updater }
            case .submenu(let title, let symbol, let children):
                let item = menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
                item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
                item.submenu = self.menu(title, children, bindings)
            case .command(let name, let symbol):
                guard let command = Command.all.first(where: { $0.name == name }) else { continue }
                let combos = bindings.bindings.filter { $0.action == command.action }.map(\.combo)
                let item = commandItem(command, combos.last, in: menu)
                item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
                for alternate in combos.dropLast() {
                    let hidden = commandItem(command, alternate, in: menu)
                    hidden.isHidden = true
                    hidden.allowsKeyEquivalentWhenHidden = true
                }
            }
        }
        return menu
    }

    private func commandItem(_ command: Command, _ combo: KeyCombo?, in menu: NSMenu) -> NSMenuItem {
        let keys = [
            "left": "\u{F702}", "right": "\u{F703}", "up": "\u{F700}", "down": "\u{F701}",
            "return": "\r", "tab": "\t", "plus": "+",
        ]
        let masks: [(KeyCombo.Modifiers, NSEvent.ModifierFlags)] = [
            (.command, .command), (.shift, .shift), (.option, .option), (.control, .control),
        ]
        let item = menu.addItem(
            withTitle: command.title,
            action: #selector(runMenuItem(_:)),
            keyEquivalent: combo.map { keys[$0.key] ?? $0.key } ?? ""
        )
        item.keyEquivalentModifierMask = NSEvent.ModifierFlags(
            masks.filter { combo?.modifiers.contains($0.0) == true }.map(\.1)
        )
        item.target = self
        item.tag = menuActions.count
        menuActions.append(command.action)
        return item
    }
}
