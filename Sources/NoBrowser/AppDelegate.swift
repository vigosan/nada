import AppKit
import NoBrowserCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var browser: BrowserController?
    private var menuActions: [PaletteAction] = []

    @objc private func runMenuItem(_ sender: NSMenuItem) {
        browser?.run(menuActions[sender.tag])
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let browser = BrowserController(modules: [AdBlockModule()])
        self.browser = browser
        NSApp.mainMenu = mainMenu()
        browser.window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func mainMenu() -> NSMenu {
        let app = NSMenu()
        app.addItem(withTitle: "Ocultar No Browser", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(withTitle: "Salir de No Browser", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let edit = NSMenu(title: "Edición")
        edit.addItem(withTitle: "Deshacer", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Rehacer", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(withTitle: "Cortar", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copiar", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Pegar", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Seleccionar todo", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        let navigation = NSMenu(title: "Navegación")
        let arrows = (left: "\u{F702}", right: "\u{F703}", up: "\u{F700}", down: "\u{F701}")
        let commands: [(String, String, NSEvent.ModifierFlags, PaletteAction)] = [
            ("Paleta de órdenes", "k", .command, .togglePalette),
            ("Abrir dirección", "l", .command, .openLocation),
            ("Pestaña nueva", "t", .command, .newTab),
            ("Cerrar", "w", .command, .closeTab),
            ("Recargar", "r", .command, .reload),
            ("Atrás", "[", .command, .back),
            ("Adelante", "]", .command, .forward),
            ("Herramientas de desarrollador", "i", [.command, .option], .toggleDevTools),
            ("Ajustes…", ",", .command, .openSettings),
            ("Dividir a la derecha", "d", .command, .split(.horizontal)),
            ("Dividir abajo", "d", [.command, .shift], .split(.vertical)),
            ("Panel de la izquierda", arrows.left, [.command, .option], .focusPane(.left)),
            ("Panel de la derecha", arrows.right, [.command, .option], .focusPane(.right)),
            ("Panel de arriba", arrows.up, [.command, .option], .focusPane(.up)),
            ("Panel de abajo", arrows.down, [.command, .option], .focusPane(.down)),
            ("Mover divisor a la izquierda", arrows.left, [.command, .control], .resizePane(.left)),
            ("Mover divisor a la derecha", arrows.right, [.command, .control], .resizePane(.right)),
            ("Mover divisor arriba", arrows.up, [.command, .control], .resizePane(.up)),
            ("Mover divisor abajo", arrows.down, [.command, .control], .resizePane(.down)),
        ] + (0..<9).map { ("Pestaña \($0 + 1)", "\($0 + 1)", .command, .selectTab($0)) }
        for (title, key, modifiers, action) in commands {
            let item = navigation.addItem(withTitle: title, action: #selector(runMenuItem(_:)), keyEquivalent: key)
            item.keyEquivalentModifierMask = modifiers
            item.target = self
            item.tag = menuActions.count
            menuActions.append(action)
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
