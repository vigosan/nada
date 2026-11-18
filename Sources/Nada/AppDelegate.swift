import AppKit
import NadaCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var browser: BrowserController?
    private var menuActions: [PaletteAction] = []

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
        "support": ("Soporte de Nada", #selector(openSupport(_:)), "", [], "questionmark.circle"),
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        let config = (try? String(contentsOf: Config.file, encoding: .utf8)) ?? ""
        let bindings = KeyBindings(config: config)
        bindings.errors.forEach { NSLog("%@ %@", Config.file.path, $0) }
        let theme = ThemeChoice(config: config)
        Theme.load(theme)
        let browser = BrowserController(modules: [AdBlockModule(), VimKeysModule()], bindings: bindings, theme: theme)
        self.browser = browser
        NSApp.mainMenu = mainMenu(bindings)
        browser.window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { browser?.open($0) }
    }

    func applicationWillTerminate(_ notification: Notification) {
        browser?.saveState()
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
