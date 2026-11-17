import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var browser: BrowserController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let browser = BrowserController(modules: [AdBlockModule()])
        self.browser = browser
        NSApp.mainMenu = mainMenu(for: browser)
        browser.window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func mainMenu(for browser: BrowserController) -> NSMenu {
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
        let commands: [(String, Selector, String, NSEvent.ModifierFlags)] = [
            ("Paleta de órdenes", #selector(BrowserController.togglePalette(_:)), "k", .command),
            ("Abrir dirección", #selector(BrowserController.openLocation(_:)), "l", .command),
            ("Pestaña nueva", #selector(BrowserController.newTab(_:)), "t", .command),
            ("Cerrar pestaña", #selector(BrowserController.closeTab(_:)), "w", .command),
            ("Recargar", #selector(BrowserController.reload(_:)), "r", .command),
            ("Atrás", #selector(BrowserController.goBack(_:)), "[", .command),
            ("Adelante", #selector(BrowserController.goForward(_:)), "]", .command),
            ("Herramientas de desarrollador", #selector(BrowserController.toggleDevTools(_:)), "i", [.command, .option]),
        ]
        for (title, action, key, modifiers) in commands {
            let item = navigation.addItem(withTitle: title, action: action, keyEquivalent: key)
            item.keyEquivalentModifierMask = modifiers
            item.target = browser
        }
        for index in 0..<9 {
            let item = navigation.addItem(
                withTitle: "Pestaña \(index + 1)",
                action: #selector(BrowserController.selectTab(_:)),
                keyEquivalent: "\(index + 1)"
            )
            item.tag = index
            item.target = browser
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
