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

@MainActor
@Suite("El aviso de cookies de YouTube no lo tapa ninguna lista y vuelve en cada visita: Nada lo rechaza para que no pregunte más", .serialized)
struct YouTubeConsentTests {
    private let dialog = """
        <script>
        setTimeout(() => {
          document.body.insertAdjacentHTML("beforeend", `
            <ytd-consent-bump-v2-lightbox><div class=eom-buttons>
              <div class=eom-button-row><button onclick="window.choice = 'reject'">Rechazar todo</button><button onclick="window.choice = 'accept'">Aceptar todo</button></div>
              <div class=eom-button-row><button onclick="window.choice = 'more'">Más opciones</button></div>
            </div></ytd-consent-bump-v2-lightbox>`);
        }, 100);
        </script>
        """

    private func choice(on address: String) async throws -> String? {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(
            WKUserScript(source: ConsentWalls.rejectYouTube, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        )
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 300), configuration: configuration)
        webView.loadHTMLString("<body>\(dialog)</body>", baseURL: URL(string: address))
        while webView.isLoading { try await Task.sleep(for: .milliseconds(20)) }
        try await Task.sleep(for: .milliseconds(400))
        return try await webView.evaluateJavaScript("window.choice || null") as? String
    }

    @Test("rechaza aunque el aviso llegue después de cargar, que es como lo pinta YouTube, y en cualquier idioma")
    func rejectsTheLateDialog() async throws {
        #expect(try await choice(on: "https://www.youtube.com/watch?v=x") == "reject")
    }

    @Test("en otras webs no pulsa nada: ese botón allí podría ser cualquier cosa")
    func leavesOtherSitesAlone() async throws {
        #expect(try await choice(on: "https://example.com/") == nil)
    }
}
