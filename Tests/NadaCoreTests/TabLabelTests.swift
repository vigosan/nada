import Foundation
import Testing
@testable import NadaCore

@Suite("La pestaña activa dice en qué sitio estás, porque el título lo escribe la página y puede mentir")
struct TabLabelTests {
    private func label(_ title: String, _ address: String?, active: Bool = true) -> String {
        TabLabel.text(title: title, address: address.flatMap { URL(string: $0) }, active: active)
    }

    @Test("delante del título va el dominio real, sin el www que no aporta nada")
    func activeTabLeadsWithTheHost() {
        #expect(label("Inicia sesión en tu banco", "https://www.banco-falso.example/login") == "banco-falso.example — Inicia sesión en tu banco")
    }

    @Test("las demás pestañas se quedan con su título para que quepan más")
    func otherTabsKeepTheirTitle() {
        #expect(label("Docs", "https://example.com/docs", active: false) == "Docs")
    }

    @Test("una página sin cifrar lo dice con su esquema, que es el único aviso que hay sin barra de direcciones")
    func plainHTTPIsVisible() {
        #expect(label("Router", "http://192.168.1.1/") == "http://192.168.1.1 — Router")
    }

    @Test("si el título ya es el dominio no se repite")
    func hostIsNotRepeated() {
        #expect(label("example.com", "https://example.com/") == "example.com")
    }

    @Test("un dominio con letras de otro alfabeto se enseña en su forma ASCII para que no imite a otro")
    func lookalikeHostsAreShownEncoded() {
        let shown = label("Apple", "https://\u{430}pple.com/")
        #expect(shown == "xn--pple-43d.com — Apple")
    }

    @Test("la pestaña que suena lleva una nota, esté activa o no, para encontrar de dónde sale el ruido")
    func playingTabsAreMarked() {
        let site = URL(string: "https://musica.example/")
        #expect(TabLabel.text(title: "Lista", address: site, active: false, playing: true) == "♪ Lista")
        #expect(TabLabel.text(title: "Lista", address: site, active: true, playing: true) == "♪ musica.example — Lista")
        #expect(TabLabel.text(title: "Lista", address: site, active: false, playing: false) == "Lista")
    }

    @Test("callar todo lo que suena se hace con una orden, porque no hay un altavoz en cada pestaña donde pulsar")
    func mediaIsPausedFromThePalette() {
        #expect(Palette.items(query: "pausar", tabTitles: []).first?.action == .pauseMedia)
    }

    @Test("las páginas que no vienen de un sitio web, como las de una extensión o la pestaña vacía, solo llevan título")
    func pagesWithoutASiteKeepTheirTitle() {
        #expect(label("Pestaña nueva", nil) == "Pestaña nueva")
        #expect(label("1Password", "webkit-extension://abc/app.html") == "1Password")
        #expect(label("Notas", "file:///Users/x/notas.html") == "Notas")
    }
}
