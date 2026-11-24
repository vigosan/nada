import Foundation
import Testing
import WebKit
@testable import NadaCore

@MainActor
@Suite("La velocidad del vídeo se cambia con el teclado y sin el tope de 2× que pone YouTube", .serialized)
struct PlaybackSpeedTests {
    private func page(_ body: String) async throws -> WKWebView {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        webView.loadHTMLString("<body>\(body)</body>", baseURL: URL(string: "https://example.com/"))
        while webView.isLoading { try await Task.sleep(for: .milliseconds(20)) }
        return webView
    }

    private func change(_ webView: WKWebView, by step: Double, times: Int = 1) async throws -> String {
        var result = ""
        for _ in 0..<times {
            result = try #require(try await webView.evaluateJavaScript(PlaybackSpeed.change(by: step)) as? String)
        }
        return result
    }

    private func rate(_ webView: WKWebView, _ id: String) async throws -> Double {
        try #require(try await webView.evaluateJavaScript("\(id).playbackRate") as? Double)
    }

    private let videos = "<video id=small style='width: 40px; height: 30px'></video><video id=big style='width: 200px; height: 100px'></video>"

    @Test("acelera el vídeo más grande de cuarto en cuarto, y no las miniaturas")
    func speedsUpTheLargestVideo() async throws {
        let webView = try await page(videos)
        #expect(try await change(webView, by: 0.25) == "1.25×")
        #expect(try await rate(webView, "big") == 1.25)
        #expect(try await rate(webView, "small") == 1)
    }

    @Test("pasa de 2× hasta 4×, que es lo que se aguanta escuchando una charla")
    func goesPastTwoUpToFour() async throws {
        let webView = try await page(videos)
        #expect(try await change(webView, by: 0.25, times: 20) == "4×")
        #expect(try await rate(webView, "big") == 4)
    }

    @Test("frena hasta 0,25× y no más, porque a cero el vídeo se pararía sin decir por qué")
    func slowsDownToAQuarter() async throws {
        let webView = try await page(videos)
        #expect(try await change(webView, by: -0.25, times: 10) == "0.25×")
        #expect(try await rate(webView, "big") == 0.25)
    }

    @Test("enseña la velocidad en la página, porque YouTube no se entera y su menú seguiría diciendo 1×")
    func showsTheSpeed() async throws {
        let webView = try await page(videos)
        _ = try await change(webView, by: 0.25, times: 2)
        #expect(try await webView.evaluateJavaScript("document.body.innerText.includes('1.5×')") as? Bool == true)
    }

    @Test("sin vídeo en la página no hace nada")
    func withoutVideoNothingHappens() async throws {
        let webView = try await page("<p>texto</p>")
        #expect(try await change(webView, by: 0.25) == "none")
    }
}
