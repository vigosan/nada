import Foundation
import Testing
@testable import NadaCore

@Suite("Lo que una página necesita del navegador cuando algo no va bien")
struct PagesTests {
    @Test("un fallo de carga dice qué sitio falló y por qué, y ofrece reintentar")
    func errorPageExplainsTheFailure() {
        let html = ErrorPage.html(url: URL(string: "https://example.invalid/pagina")!, reason: "No se encuentra el servidor.")
        #expect(html.contains("example.invalid"))
        #expect(html.contains("No se encuentra el servidor."))
        #expect(html.contains("href=\"https://example.invalid/pagina\""))
    }

    @Test("el texto del error no puede colar HTML en la página de aviso")
    func errorPageEscapesItsText() {
        let html = ErrorPage.html(url: URL(string: "https://example.com/?a=%22%3E%3Cb%3E")!, reason: "<script>alert(1)</script>")
        #expect(!html.contains("<script>alert(1)</script>"))
        #expect(html.contains("&lt;script&gt;"))
    }

    @Test("un enlace pulsado con ⌘ o con el botón central se abre en otra pestaña; un clic normal sigue en la misma")
    func modifiedClicksOpenANewTab() {
        #expect(LinkClick.opensNewTab(command: true, button: 0))
        #expect(LinkClick.opensNewTab(command: false, button: 2))
        #expect(!LinkClick.opensNewTab(command: false, button: 0))
        #expect(!LinkClick.opensNewTab(command: false, button: 1))
    }

    @Test("un sitio que pide usuario y contraseña se pregunta a la persona, un certificado se revisa, y lo demás lo resuelve el sistema")
    func challengesAreSortedByWhoAnswersThem() {
        #expect(Challenge(method: NSURLAuthenticationMethodHTTPBasic) == .credentials)
        #expect(Challenge(method: NSURLAuthenticationMethodHTTPDigest) == .credentials)
        #expect(Challenge(method: NSURLAuthenticationMethodNTLM) == .credentials)
        #expect(Challenge(method: NSURLAuthenticationMethodServerTrust) == .trust)
        #expect(Challenge(method: NSURLAuthenticationMethodClientCertificate) == .system)
    }

    @Test("una descarga nunca pisa un archivo que ya existe: se numera")
    func downloadsGetAFreeName() {
        let taken: Set<String> = ["informe.pdf", "informe 2.pdf", "datos"]
        #expect(Downloads.freeName(for: "nuevo.pdf") { taken.contains($0) } == "nuevo.pdf")
        #expect(Downloads.freeName(for: "informe.pdf") { taken.contains($0) } == "informe 3.pdf")
        #expect(Downloads.freeName(for: "datos") { taken.contains($0) } == "datos 2")
    }

    @Test("un nombre de descarga con rutas no puede escribir fuera de la carpeta de descargas")
    func downloadNamesCannotEscapeTheFolder() {
        #expect(Downloads.freeName(for: "../../.zshrc") { _ in false } == ".zshrc")
        #expect(Downloads.freeName(for: "") { _ in false } == "descarga")
    }

    @Test("la sesión recuerda las pestañas con página y cuál estaba activa, y olvida las vacías")
    func sessionKeepsOnlyRealPages() {
        let session = Session(
            pages: [
                SessionPage(url: URL(string: "https://a.example/")!, title: "A"),
                nil,
                SessionPage(url: URL(string: "https://b.example/")!, title: "B"),
            ],
            active: 2
        )
        #expect(session.tabs.map(\.title) == ["A", "B"])
        #expect(session.active == 1)
        #expect(Session(pages: [nil, nil], active: 1).tabs.isEmpty)
    }

    @Test("cada pestaña vuelve con su atrás y adelante, y las cerradas se pueden seguir reabriendo tras reiniciar")
    func sessionKeepsNavigationAndClosedTabs() throws {
        let page = SessionPage(url: URL(string: "https://a.example/")!, title: "A", state: Data([1, 2, 3]))
        let closed = (1...30).map { URL(string: "https://cerrada.example/\($0)")! }
        let session = Session(pages: [page], active: 0, closed: closed)
        let restored = try JSONDecoder().decode(Session.self, from: JSONEncoder().encode(session))
        #expect(restored.tabs == [page])
        #expect(restored.closed == Array(closed.suffix(20)))
    }

    @Test("una sesión guardada por una versión anterior, sin esos datos, se sigue abriendo")
    func olderSessionsStillOpen() throws {
        let saved = Data(#"{"tabs":[{"url":"https://a.example/","title":"A"}],"active":0}"#.utf8)
        let session = try JSONDecoder().decode(Session.self, from: saved)
        #expect(session.tabs == [SessionPage(url: URL(string: "https://a.example/")!, title: "A")])
        #expect(session.closed.isEmpty)
    }

    @Test("una pestaña dividida vuelve con todos sus paneles y no solo con el que tenía el foco")
    func sessionKeepsSplitPanes() throws {
        var layout = PaneLayout()
        let second = layout.split(.horizontal)
        let other = SessionPage(url: URL(string: "https://otro.example/")!, title: "Otro")
        let page = SessionPage(
            url: URL(string: "https://a.example/")!,
            title: "A",
            split: SessionSplit(layout: layout, others: [0: other])
        )
        let restored = try JSONDecoder().decode(Session.self, from: JSONEncoder().encode(Session(pages: [page], active: 0)))
        #expect(restored.tabs.first?.split?.others == [0: other])
        #expect(restored.tabs.first?.split?.layout.focused == second)
    }
}
