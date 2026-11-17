import Foundation
import Testing
@testable import NoBrowserCore

@Suite("Lo que se escribe en la paleta llega al sitio que la persona esperaba")
struct AddressResolverTests {
    @Test("un dominio sin esquema se abre cifrado para no exponer la navegación")
    func bareDomainUsesHTTPS() {
        #expect(AddressResolver.url(for: "example.com/docs")?.absoluteString == "https://example.com/docs")
    }

    @Test("un esquema escrito a mano se respeta tal cual")
    func explicitSchemeIsKept() {
        #expect(AddressResolver.url(for: "http://example.com")?.absoluteString == "http://example.com")
    }

    @Test("los servidores de desarrollo locales no tienen certificado y van por http")
    func localServersUseHTTP() {
        #expect(AddressResolver.url(for: "localhost:5173")?.absoluteString == "http://localhost:5173")
        #expect(AddressResolver.url(for: "127.0.0.1:3000/api")?.absoluteString == "http://127.0.0.1:3000/api")
    }

    @Test("un texto con espacios es una búsqueda, no una dirección rota")
    func wordsBecomeASearch() {
        let url = AddressResolver.url(for: "swift webkit inspector")
        #expect(url?.host() == "duckduckgo.com")
        #expect(url?.query() == "q=swift%20webkit%20inspector")
    }

    @Test("una sola palabra sin punto es una búsqueda")
    func singleWordIsASearch() {
        #expect(AddressResolver.isAddress("ghostty") == false)
        #expect(AddressResolver.url(for: "ghostty")?.host() == "duckduckgo.com")
    }

    @Test("los caracteres reservados de una búsqueda no rompen la consulta")
    func searchEscapesReservedCharacters() {
        #expect(AddressResolver.url(for: "a&b = c+d")?.query() == "q=a%26b%20%3D%20c%2Bd")
    }

    @Test("la búsqueda va al buscador elegido en ajustes, no a uno impuesto")
    func searchUsesTheChosenEngine() {
        #expect(AddressResolver.url(for: "paella", searchEngine: .google)?.absoluteString == "https://www.google.com/search?q=paella")
        #expect(AddressResolver.url(for: "paella", searchEngine: .brave)?.absoluteString == "https://search.brave.com/search?q=paella")
    }

    @Test("cambiar de buscador recorre todos y vuelve al primero para no quedarse atascado")
    func enginesCycle() {
        #expect(SearchEngine.duckDuckGo.next == .google)
        #expect(SearchEngine.brave.next == .duckDuckGo)
    }

    @Test("sin texto no hay a dónde ir")
    func emptyInputGoesNowhere() {
        #expect(AddressResolver.url(for: "   ") == nil)
    }
}
