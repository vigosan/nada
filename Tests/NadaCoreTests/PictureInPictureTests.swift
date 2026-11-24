import Foundation
import Testing
import WebKit
@testable import NadaCore

@MainActor
@Suite("Un vídeo puede seguir viéndose flotando encima de todo mientras se trabaja en otra cosa", .serialized)
struct PictureInPictureTests {
    private let presentation = """
        <script>
        const modes = new WeakMap();
        Object.defineProperty(HTMLVideoElement.prototype, "webkitPresentationMode", { get() { return modes.get(this) || "inline"; } });
        HTMLVideoElement.prototype.webkitSetPresentationMode = function (mode) { modes.set(this, mode); };
        </script>
        """

    private func page(_ body: String) async throws -> WKWebView {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        webView.loadHTMLString("<body>\(presentation)\(body)</body>", baseURL: URL(string: "https://example.com/"))
        while webView.isLoading { try await Task.sleep(for: .milliseconds(20)) }
        return webView
    }

    private func toggle(_ webView: WKWebView) async throws -> String {
        try #require(try await webView.evaluateJavaScript(PictureInPicture.toggle) as? String)
    }

    private func mode(_ webView: WKWebView, _ id: String) async throws -> String {
        try #require(try await webView.evaluateJavaScript("\(id).webkitPresentationMode") as? String)
    }

    @Test("saca a flotar el vídeo más grande, que es el que se está viendo y no una miniatura")
    func floatsTheLargestVideo() async throws {
        let webView = try await page("<video id=small style='width: 40px; height: 30px'></video><video id=big style='width: 200px; height: 100px'></video>")
        #expect(try await toggle(webView) == "on")
        #expect(try await mode(webView, "big") == "picture-in-picture")
        #expect(try await mode(webView, "small") == "inline")
    }

    @Test("la misma orden lo devuelve a la página")
    func togglingAgainBringsItBack() async throws {
        let webView = try await page("<video id=big style='width: 200px; height: 100px'></video>")
        _ = try await toggle(webView)
        #expect(try await toggle(webView) == "off")
        #expect(try await mode(webView, "big") == "inline")
    }

    @Test("lo devuelve aunque el que flota ya no sea el más grande, porque al salir de la página su hueco se encoge")
    func bringsBackWhicheverIsFloating() async throws {
        let webView = try await page("<video id=small style='width: 40px; height: 30px'></video><video id=big style='width: 200px; height: 100px'></video>")
        _ = try await webView.evaluateJavaScript("small.webkitSetPresentationMode('picture-in-picture')")
        #expect(try await toggle(webView) == "off")
        #expect(try await mode(webView, "small") == "inline")
        #expect(try await mode(webView, "big") == "inline")
    }

    @Test("sin vídeo en la página no hace nada")
    func withoutVideoNothingHappens() async throws {
        let webView = try await page("<p>texto</p>")
        #expect(try await toggle(webView) == "none")
    }
}
