import Foundation
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
}
