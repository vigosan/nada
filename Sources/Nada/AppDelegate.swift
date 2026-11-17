import AppKit
import NadaCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var browser: BrowserController?
    private var menuActions: [PaletteAction] = []

    @objc private func runMenuItem(_ sender: NSMenuItem) {
        let action = menuActions[sender.tag]
        if [.back, .forward].contains(action), let editor = browser?.window.firstResponder as? NSTextView, let event = NSApp.currentEvent {
            editor.keyDown(with: event)
            return
        }
        browser?.run(action)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let bindings = KeyBindings(config: (try? String(contentsOf: Config.file, encoding: .utf8)) ?? "")
        bindings.errors.forEach { NSLog("%@ %@", Config.file.path, $0) }
        let browser = BrowserController(modules: [AdBlockModule()], bindings: bindings)
        self.browser = browser
        NSApp.mainMenu = mainMenu(bindings)
        browser.window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func mainMenu(_ bindings: KeyBindings) -> NSMenu {
        let app = NSMenu()
        app.addItem(withTitle: "Ocultar Nada", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(withTitle: "Salir de Nada", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let edit = NSMenu(title: "Edición")
        edit.addItem(withTitle: "Deshacer", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Rehacer", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(withTitle: "Cortar", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copiar", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Pegar", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Seleccionar todo", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let navigation = NSMenu(title: "Navegación")
        let arrows = [
            "left": "\u{F702}", "right": "\u{F703}", "up": "\u{F700}", "down": "\u{F701}",
            "return": "\r", "tab": "\t", "plus": "+",
        ]
        let masks: [(KeyCombo.Modifiers, NSEvent.ModifierFlags)] = [
            (.command, .command), (.shift, .shift), (.option, .option), (.control, .control),
        ]
        for binding in bindings.bindings {
            let title = Command.all.first { $0.action == binding.action }?.title ?? ""
            let key = arrows[binding.combo.key] ?? binding.combo.key
            let item = navigation.addItem(withTitle: title, action: #selector(runMenuItem(_:)), keyEquivalent: key)
            item.keyEquivalentModifierMask = NSEvent.ModifierFlags(
                masks.filter { binding.combo.modifiers.contains($0.0) }.map(\.1)
            )
            item.target = self
            item.tag = menuActions.count
            menuActions.append(binding.action)
        }

        let main = NSMenu()
        for submenu in [app, edit, navigation] {
            let item = NSMenuItem()
            item.submenu = submenu
            main.addItem(item)
        }
        return main
    }
}
