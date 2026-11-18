import Foundation
import JavaScriptCore
import Testing
import WebKit
@testable import NadaCore

@MainActor
@Suite("Una extensión hecha para otro navegador no se rompe por las API que WebKit no trae", .serialized)
struct ExtensionShimTests {
    private func page(existing: String) async throws -> WKWebView {
        let configuration = WKWebViewConfiguration()
        for source in ["window.chrome = \(existing); window.browser = window.chrome;", ExtensionShim.script] {
            configuration.userContentController.addUserScript(
                WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
            )
        }
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 300), configuration: configuration)
        webView.loadHTMLString("<body></body>", baseURL: URL(string: "https://example.com/"))
        while webView.isLoading { try await Task.sleep(for: .milliseconds(20)) }
        return webView
    }

    private func evaluate<Value>(_ script: String, in webView: WKWebView) async throws -> Value? {
        try await webView.callAsyncJavaScript("return \(script)", contentWorld: .page) as? Value
    }

    @Test("los avisos del sistema se aceptan y no hacen nada, así el arranque de la extensión no se corta")
    func notificationsAreAccepted() async throws {
        let webView = try await page(existing: "{ runtime: {} }")
        let listens: String = try #require(await evaluate("typeof chrome.notifications.onClicked.addListener", in: webView))
        #expect(listens == "function")
        let created: String = try #require(await evaluate("await chrome.notifications.create('aviso', {})", in: webView))
        #expect(created == "aviso")
        let viaCallback: String = try #require(
            await evaluate("await new Promise((resolve) => browser.notifications.create('otro', {}, resolve))", in: webView)
        )
        #expect(viaCallback == "otro")
    }

    @Test("a la navegación se le añade solo el aviso que falta, sin tocar los que WebKit ya da")
    func missingNavigationEventIsAdded() async throws {
        let webView = try await page(existing: "{ webNavigation: { onCommitted: 'real' } }")
        let added: String = try #require(
            await evaluate("typeof chrome.webNavigation.onCreatedNavigationTarget.addListener", in: webView)
        )
        #expect(added == "function")
        let kept: String = try #require(await evaluate("chrome.webNavigation.onCommitted", in: webView))
        #expect(kept == "real")
    }

    @Test("lo que WebKit ya ofrece se deja como está")
    func existingAPIsAreKept() async throws {
        let webView = try await page(existing: "{ notifications: { real: 'sí' } }")
        let kept: String = try #require(await evaluate("chrome.notifications.real", in: webView))
        #expect(kept == "sí")
    }

    @Test("una página normal, sin API de extensiones, no recibe nada")
    func ordinaryPagesAreUntouched() async throws {
        let webView = try await page(existing: "undefined")
        let chrome: String = try #require(await evaluate("typeof window.chrome", in: webView))
        #expect(chrome == "undefined")
    }

    @Test("la configuración de empresa se responde vacía, que es lo que 1Password espera cuando nadie lo administra")
    func managedStorageAnswersEmpty() async throws {
        let webView = try await page(existing: "{ storage: { local: 'real' } }")
        let managed: String = try #require(await evaluate("JSON.stringify(await browser.storage.managed.get())", in: webView))
        #expect(managed == "{}")
        let kept: String = try #require(await evaluate("chrome.storage.local", in: webView))
        #expect(kept == "real")
    }

    @Test("también vale en el proceso de fondo de la extensión, donde no existe window")
    func worksWithoutAWindow() throws {
        let context = try #require(JSContext())
        context.evaluateScript("globalThis.chrome = { webNavigation: {} }; globalThis.browser = globalThis.chrome;")
        context.evaluateScript(ExtensionShim.script)
        #expect(context.exception == nil)
        #expect(context.evaluateScript("typeof chrome.webNavigation.onCreatedNavigationTarget.addListener").toString() == "function")
        #expect(context.evaluateScript("typeof browser.notifications.create").toString() == "function")
    }

    @Test("WebKit suelta los espacios de API que nadie sujeta, y con ellos lo añadido: por eso se quedan sujetos")
    func extendedNamespacesAreHeld() throws {
        let context = try #require(JSContext())
        context.evaluateScript("globalThis.chrome = { storage: {}, tabs: {} };")
        context.evaluateScript(ExtensionShim.script)
        #expect(context.evaluateScript("nadaKept.includes(chrome.storage)").toBool())
        #expect(!context.evaluateScript("nadaKept.includes(chrome.tabs)").toBool())
    }

    private func manifest(_ background: String) -> Data {
        Data(#"{"name":"Prueba","manifest_version":3,"background":\#(background)}"#.utf8)
    }

    private func background(of manifest: Data) throws -> [String: String] {
        let json = try #require(try JSONSerialization.jsonObject(with: manifest) as? [String: Any])
        return try #require(json["background"] as? [String: String])
    }

    @Test("el proceso de fondo no recibe scripts de usuario, así que se le pone delante un arranque que carga primero lo que falta")
    func wrapsAModuleWorker() throws {
        let wrapped = try #require(ExtensionShim.wrapping(manifest(#"{"service_worker":"background/background.js","type":"module"}"#)))
        #expect(try background(of: wrapped.manifest) == ["service_worker": ExtensionShim.workerFile, "type": "module"])
        #expect(wrapped.worker == "import \"./\(ExtensionShim.shimFile)\";\nimport \"./background/background.js\";\n")
        let rest = try #require(try JSONSerialization.jsonObject(with: wrapped.manifest) as? [String: Any])
        #expect(rest["name"] as? String == "Prueba")
    }

    @Test("un proceso de fondo clásico no admite import, y se carga con importScripts")
    func wrapsAClassicWorker() throws {
        let wrapped = try #require(ExtensionShim.wrapping(manifest(#"{"service_worker":"sw.js"}"#)))
        #expect(try background(of: wrapped.manifest) == ["service_worker": ExtensionShim.workerFile])
        #expect(wrapped.worker == "importScripts(\"\(ExtensionShim.shimFile)\", \"sw.js\");\n")
    }

    @Test("lo ya envuelto no se envuelve otra vez, o el arranque se cargaría a sí mismo")
    func doesNotWrapTwice() throws {
        let once = try #require(ExtensionShim.wrapping(manifest(#"{"service_worker":"sw.js"}"#)))
        #expect(ExtensionShim.wrapping(once.manifest) == nil)
    }

    @Test("una extensión con página de fondo ya recibe lo que falta como script de usuario y no se toca")
    func leavesBackgroundPagesAlone() {
        #expect(ExtensionShim.wrapping(manifest(#"{"scripts":["background.js"]}"#)) == nil)
        #expect(ExtensionShim.wrapping(Data("no es json".utf8)) == nil)
    }
}
