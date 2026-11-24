import Foundation
import Testing
import WebKit
@testable import NadaCore

@MainActor
@Suite("Un vídeo se ve mejor ocupando la ventana entera, sin salir a la pantalla completa del Mac", .serialized)
struct VideoFillTests {
    private func page(_ body: String) async throws -> WKWebView {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        webView.loadHTMLString("<body style='margin: 0; height: 2000px'>\(body)</body>", baseURL: URL(string: "https://example.com/"))
        while webView.isLoading { try await Task.sleep(for: .milliseconds(20)) }
        return webView
    }

    private func toggle(_ webView: WKWebView) async throws -> String {
        try #require(try await webView.evaluateJavaScript(VideoFill.toggle) as? String)
    }

    private func frame(_ webView: WKWebView, _ selector: String) async throws -> String {
        let script = "(() => { const r = document.querySelector('\(selector)').getBoundingClientRect(); return [r.x, r.y, r.width, r.height].join(' ') })()"
        return try #require(try await webView.evaluateJavaScript(script) as? String)
    }

    private let player = """
        <div style='padding: 40px'><div id=player style='width: 160px; height: 90px; position: relative'>
        <video style='width: 160px; height: 90px'></video><div id=controls style='position: absolute; bottom: 0'>▶</div>
        </div></div>
        """

    @Test("lo que llena la ventana es el reproductor entero, para no perder sus controles ni subtítulos")
    func thePlayerFillsTheWindow() async throws {
        let webView = try await page(player)
        #expect(try await toggle(webView) == "on")
        #expect(try await frame(webView, "#player") == "0 0 400 300")
        #expect(try await frame(webView, "video") == "0 0 400 300")
        #expect(try await webView.evaluateJavaScript("player.contains(controls)") as? Bool == true)
    }

    @Test("también cuando el vídeo va suelto dentro de una caja sin altura, que es como lo monta YouTube")
    func climbsPastCollapsedWrappers() async throws {
        let webView = try await page("""
            <div style='padding: 40px'><div id=player style='width: 160px; height: 90px; position: relative'>
            <div><video style='position: absolute; top: 0; left: 0; width: 160px; height: 90px'></video></div>
            <div id=controls style='position: absolute; bottom: 0'>▶</div>
            </div></div>
            """)
        _ = try await toggle(webView)
        #expect(try await frame(webView, "#player") == "0 0 400 300")
        #expect(try await frame(webView, "video") == "0 0 400 300")
    }

    @Test("las capas de dentro se estiran con él, porque YouTube les fija la altura en píxeles y los controles se quedarían a media pantalla")
    func innerLayersStretchToo() async throws {
        let webView = try await page("""
            <div id=outer style='width: 160px; height: 90px'>
            <div id=player style='width: 160px; height: 90px; position: relative'>
            <div style='position: relative; padding-top: 56.25%'><div style='position: absolute; top: 0; width: 160px; height: 90px'>
            <div style='position: relative; height: 0'><video style='position: absolute; top: 0; left: 0; width: 160px; height: 90px'></video></div>
            <div id=controls style='position: absolute; bottom: 0; height: 10px'>▶</div>
            </div></div></div></div>
            """)
        _ = try await toggle(webView)
        #expect(try await frame(webView, "#player") == "0 0 400 300")
        #expect(try await frame(webView, "video") == "0 0 400 300")
        #expect(try await webView.evaluateJavaScript("controls.getBoundingClientRect().bottom") as? Double == 300)
    }

    @Test("llena la ventana aunque la página esté desplazada, que es lo normal al leer los comentarios")
    func fillsEvenWhenScrolled() async throws {
        let webView = try await page(player)
        _ = try await webView.evaluateJavaScript("scrollTo(0, 500)")
        _ = try await toggle(webView)
        #expect(try await frame(webView, "#player") == "0 0 400 300")
    }

    @Test("elige el vídeo más grande, no las miniaturas que se reproducen al pasar por encima")
    func picksTheLargestVideo() async throws {
        let webView = try await page("<video id=small style='width: 40px; height: 30px'></video><video id=big style='width: 200px; height: 100px'></video>")
        _ = try await toggle(webView)
        #expect(try await frame(webView, "#big") == "0 0 400 300")
        #expect(try await frame(webView, "#small") != "0 0 400 300")
    }

    @Test("un contenedor transformado no lo deja encerrado, porque las webs los usan para animar")
    func transformedAncestorsDoNotTrapIt() async throws {
        let webView = try await page("<div style='transform: translateX(50px); margin-top: 60px'>\(player)</div>")
        _ = try await toggle(webView)
        #expect(try await frame(webView, "#player") == "0 0 400 300")
    }

    @Test("la misma orden lo devuelve a su sitio, como estaba")
    func togglingAgainRestores() async throws {
        let webView = try await page(player)
        let before = try await frame(webView, "#player")
        _ = try await toggle(webView)
        #expect(try await toggle(webView) == "off")
        #expect(try await frame(webView, "#player") == before)
    }

    @Test("escape también lo devuelve, que es la tecla con la que se sale de la pantalla completa")
    func escapeRestores() async throws {
        let webView = try await page(player)
        let before = try await frame(webView, "#player")
        _ = try await toggle(webView)
        _ = try await webView.evaluateJavaScript("document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }))")
        #expect(try await frame(webView, "#player") == before)
        #expect(try await toggle(webView) == "on")
    }

    @Test("sin vídeo en la página no toca nada")
    func withoutVideoNothingChanges() async throws {
        let webView = try await page("<p id=text>texto</p>")
        let before = try await frame(webView, "#text")
        #expect(try await toggle(webView) == "none")
        #expect(try await frame(webView, "#text") == before)
    }
}
