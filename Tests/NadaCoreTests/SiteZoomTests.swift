import Foundation
import Testing
@testable import NadaCore

@Suite("El tamaño que eliges para un sitio se recuerda, para no agrandarlo cada vez que vuelves")
struct SiteZoomTests {
    @Test("cada sitio guarda su tamaño y los demás siguen al normal")
    func remembersPerSite() {
        var zoom = SiteZoom()
        zoom.set(1.25, for: URL(string: "https://letra-pequena.example/articulo"))
        #expect(zoom.factor(for: URL(string: "https://letra-pequena.example/otra-pagina")) == 1.25)
        #expect(zoom.factor(for: URL(string: "https://example.com/")) == 1)
    }

    @Test("volver al tamaño real olvida el sitio en vez de guardar un uno")
    func resettingForgetsTheSite() throws {
        var zoom = SiteZoom()
        let site = URL(string: "https://example.com/")
        zoom.set(1.5, for: site)
        zoom.set(1, for: site)
        #expect(zoom == SiteZoom())
    }

    @Test("acercar y luego alejar deja el sitio al tamaño normal aunque la cuenta no dé un uno exacto")
    func roundingBackToNormalForgetsTheSite() {
        var zoom = SiteZoom()
        zoom.set(1.1 * (1 / 1.1) * 1.1 * (1 / 1.1) * 1.1 * (1 / 1.1), for: URL(string: "https://example.com/"))
        zoom.set(1.0000000000000002, for: URL(string: "https://example.org/"))
        #expect(zoom == SiteZoom())
    }

    @Test("lo que no es un sitio web, como una página en blanco, no se recuerda")
    func ignoresPagesWithoutASite() {
        var zoom = SiteZoom()
        zoom.set(2, for: nil)
        zoom.set(2, for: URL(string: "about:blank"))
        #expect(zoom == SiteZoom())
        #expect(zoom.factor(for: nil) == 1)
    }

    @Test("se guarda en disco y vuelve igual al abrir Nada otro día")
    func survivesARoundTrip() throws {
        var zoom = SiteZoom()
        zoom.set(0.8, for: URL(string: "https://example.com/"))
        let restored = try JSONDecoder().decode(SiteZoom.self, from: JSONEncoder().encode(zoom))
        #expect(restored == zoom)
    }
}
