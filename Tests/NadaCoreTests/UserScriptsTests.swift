import Testing
import WebKit
@testable import NadaCore

@MainActor
@Suite("Todas las páginas comparten scripts: apagar uno desde Ajustes no puede llevarse los de los demás")
struct UserScriptsTests {
    private let cookies = WKUserScript(source: "cookies", injectionTime: .atDocumentStart, forMainFrameOnly: true)
    private let vim = WKUserScript(source: "vim", injectionTime: .atDocumentEnd, forMainFrameOnly: true)

    @Test("apagar las teclas vim deja el script que quita los avisos de cookies")
    func disablingKeepsTheOthers() {
        let controller = WKUserContentController()
        controller.addUserScript(cookies)
        controller.addUserScript(vim)
        controller.setUserScript(vim, enabled: false)
        #expect(controller.userScripts.map(\.source) == ["cookies"])
    }

    @Test("volver a encenderlas lo pone una sola vez, porque dos copias moverían la página el doble")
    func enablingAddsItOnce() {
        let controller = WKUserContentController()
        controller.addUserScript(cookies)
        controller.addUserScript(vim)
        controller.setUserScript(vim, enabled: true)
        controller.setUserScript(vim, enabled: false)
        controller.setUserScript(vim, enabled: true)
        #expect(controller.userScripts.map(\.source) == ["cookies", "vim"])
    }
}
