import Foundation
import Testing
import WebKit
@testable import NadaCore

@MainActor
@Suite("Atrás y adelante comparten tecla con mover el cursor: hay que saber si se está escribiendo en la página", .serialized)
struct PageFocusTests {
    private func typing(_ body: String) async throws -> Bool {
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        webView.loadHTMLString("<body>\(body)</body>", baseURL: URL(string: "https://example.com/"))
        while webView.isLoading { try await Task.sleep(for: .milliseconds(20)) }
        return try #require(try await webView.evaluateJavaScript(PageFocus.isTyping) as? Bool)
    }

    @Test("con el cursor en un campo de texto se está escribiendo, y ir atrás tiraría lo escrito")
    func textFieldsCountAsTyping() async throws {
        #expect(try await typing("<input id=a value='hola'><script>a.focus()</script>"))
        #expect(try await typing("<textarea id=a></textarea><script>a.focus()</script>"))
        #expect(try await typing("<div id=a contenteditable=true>hola</div><script>a.focus()</script>"))
    }

    @Test("un campo dentro de un componente con sombra también cuenta, que es donde lo ponen muchas webs")
    func shadowFieldsCountAsTyping() async throws {
        let body = "<div id=h></div><script>const r = h.attachShadow({ mode: 'open' }); r.innerHTML = '<input>'; r.querySelector('input').focus()</script>"
        #expect(try await typing(body))
    }

    @Test("sin campo de texto activo no se escribe nada, y la tecla navega")
    func otherElementsDoNot() async throws {
        #expect(try await typing("<p>texto</p>") == false)
        #expect(try await typing("<button id=a>ok</button><script>a.focus()</script>") == false)
        #expect(try await typing("<input type=checkbox id=a><script>a.focus()</script>") == false)
    }
}
