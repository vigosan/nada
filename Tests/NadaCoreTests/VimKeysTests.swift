import Foundation
import Testing
import WebKit
@testable import NadaCore

@MainActor
@Suite("Las teclas vim mueven la página y pulsan enlaces sin tocar el ratón", .serialized)
struct VimKeysTests {
    private let links = (0..<30).map { "<a href='#l\($0)' onclick='window.clicked=\($0)' style='display:block;height:20px'>enlace \($0)</a>" }.joined()

    private func page(_ body: String) async throws -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(
            WKUserScript(source: VimKeys.script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        )
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600), configuration: configuration)
        let window = NSWindow(contentRect: webView.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = webView
        webView.loadHTMLString("<body style='margin:0'>\(body)</body>", baseURL: URL(string: "https://example.com/"))
        while webView.isLoading { try await Task.sleep(for: .milliseconds(20)) }
        return webView
    }

    private func press(_ keys: String..., in webView: WKWebView) async throws {
        for key in keys {
            _ = try await webView.callAsyncJavaScript(
                """
                (document.activeElement || document.body).dispatchEvent(new KeyboardEvent("keydown", { key, bubbles: true, cancelable: true }));
                await new Promise((resolve) => setTimeout(resolve, 450));
                """,
                arguments: ["key": key],
                contentWorld: .page
            )
        }
    }

    private func evaluate<Value>(_ script: String, in webView: WKWebView) async throws -> Value? {
        try await webView.callAsyncJavaScript("return \(script)", contentWorld: .page) as? Value
    }

    @Test("j y k bajan y suben, G va al final y gg vuelve al principio")
    func scrolling() async throws {
        let webView = try await page("<div style='height:5000px'></div>")
        try await press("j", in: webView)
        let afterJ: Double = try #require(await evaluate("scrollY", in: webView))
        #expect(afterJ > 0)
        try await press("k", in: webView)
        #expect(try await evaluate("scrollY", in: webView) == 0.0)
        try await press("G", in: webView)
        let bottom: Double = try #require(await evaluate("scrollY", in: webView))
        #expect(bottom > 4000)
        try await press("g", "g", in: webView)
        #expect(try await evaluate("scrollY", in: webView) == 0.0)
    }

    @Test("mientras se escribe en un campo las teclas escriben y la página no se mueve")
    func typingIsLeftAlone() async throws {
        let webView = try await page("<input id='field'><div style='height:5000px'></div>")
        _ = try await webView.callAsyncJavaScript("document.getElementById('field').focus()", contentWorld: .page)
        try await press("j", "f", in: webView)
        #expect(try await evaluate("scrollY", in: webView) == 0.0)
        #expect(try await evaluate("!!document.getElementById('nada-hints')", in: webView) == false)
    }

    @Test("f etiqueta cada enlace visible con letras únicas de igual longitud, así ninguna es el principio de otra")
    func hintsAreUnambiguous() async throws {
        let webView = try await page(links + "<a href='#lejos' style='position:absolute;top:3000px'>fuera de la vista</a>")
        try await press("f", in: webView)
        let labels: [String] = try #require(await evaluate(
            "[...document.getElementById('nada-hints').shadowRoot.querySelectorAll('span')].map((tag) => tag.textContent)",
            in: webView
        ))
        #expect(labels.count == 30)
        #expect(Set(labels).count == 30)
        #expect(Set(labels.map(\.count)) == [2])
    }

    @Test("las etiquetas de enlaces pegados no se pisan, porque una etiqueta tapada no se puede leer")
    func hintsDoNotOverlap() async throws {
        let crowded = (0..<12).map { "<a href='#c\($0)' style='display:inline-block;width:8px;height:8px'></a>" }.joined()
        let webView = try await page("<div style='white-space:nowrap'>\(crowded)</div>")
        try await press("f", in: webView)
        let overlaps: Double = try #require(await evaluate(
            """
            (() => {
              const rects = [...document.getElementById('nada-hints').shadowRoot.querySelectorAll('span')].map((tag) => tag.getBoundingClientRect());
              let count = 0;
              rects.forEach((a, i) => rects.slice(i + 1).forEach((b) => {
                if (a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom) count++;
              }));
              return count;
            })()
            """,
            in: webView
        ))
        #expect(overlaps == 0)
    }

    @Test("escribir una etiqueta pulsa ese enlace y quita las etiquetas")
    func typingALabelClicksItsLink() async throws {
        let webView = try await page(links)
        try await press("f", in: webView)
        let label: String = try #require(await evaluate(
            "document.getElementById('nada-hints').shadowRoot.querySelectorAll('span')[7].textContent",
            in: webView
        ))
        try await press(String(label.first!), String(label.last!), in: webView)
        #expect(try await evaluate("window.clicked", in: webView) == 7.0)
        #expect(try await evaluate("!!document.getElementById('nada-hints')", in: webView) == false)
    }

    @Test("escape cancela las etiquetas sin pulsar nada")
    func escapeCancelsHints() async throws {
        let webView = try await page(links)
        try await press("f", "Escape", in: webView)
        #expect(try await evaluate("!!document.getElementById('nada-hints')", in: webView) == false)
        #expect(try await evaluate("window.clicked === undefined", in: webView) == true)
    }

    @Test("un campo de texto elegido con su etiqueta recibe el foco para escribir en él")
    func hintFocusesTextFields() async throws {
        let webView = try await page("<input id='field'>")
        try await press("f", in: webView)
        let label: String = try #require(await evaluate(
            "document.getElementById('nada-hints').shadowRoot.querySelector('span').textContent",
            in: webView
        ))
        try await press(label, in: webView)
        #expect(try await evaluate("document.activeElement.id", in: webView) == "field")
    }
}
