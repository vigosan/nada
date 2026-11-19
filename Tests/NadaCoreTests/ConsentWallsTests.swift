import Foundation
import Testing
import WebKit
@testable import NadaCore

@MainActor
@Suite("Ocultar un muro de cookies no basta: la web deja la página sin scroll hasta que contestas, y hay que devolvérselo", .serialized)
struct ConsentWallsTests {
    private func overflow(_ html: String) async throws -> String {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(
            WKUserScript(source: ConsentWalls.unlockScroll, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 300), configuration: configuration)
        webView.loadHTMLString(html, baseURL: URL(string: "https://example.com/"))
        while webView.isLoading { try await Task.sleep(for: .milliseconds(20)) }
        let script = "getComputedStyle(document.documentElement).overflowY + ' ' + getComputedStyle(document.body).overflowY"
        return try #require(try await webView.evaluateJavaScript(script) as? String)
    }

    @Test("la página bloqueada por Didomi, el gestor de casi toda la prensa española, vuelve a moverse")
    func didomiLockIsUndone() async throws {
        let locked = "<style>.didomi-popup-open { overflow: hidden !important }</style><body class='didomi-popup-open'>texto</body>"
        #expect(try await overflow(locked) == "visible auto")
    }

    @Test("también la bloqueada por Sourcepoint, que pone la marca en la raíz del documento")
    func sourcepointLockIsUndone() async throws {
        let locked = "<html class='sp-message-open'><style>.sp-message-open { overflow: hidden }</style><body>texto</body></html>"
        #expect(try await overflow(locked) == "auto visible")
    }

    @Test("una página que quita el scroll por su cuenta se respeta: puede ser un diálogo suyo abierto")
    func otherLocksAreKept() async throws {
        #expect(try await overflow("<body style='overflow: hidden'>texto</body>") == "visible hidden")
    }
}
