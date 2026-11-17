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
}
