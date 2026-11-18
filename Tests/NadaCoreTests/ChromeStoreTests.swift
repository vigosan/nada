import Foundation
import Testing
@testable import NadaCore

@Suite("Una extensión se instala pegando su dirección de la tienda de Chrome")
struct ChromeStoreTests {
    private let id = "nngceckbapebfimnlniiiahkandclblb"

    @Test("vale la dirección de la tienda, con o sin parámetros, y también el identificador a secas")
    func findsTheIdentifier() {
        #expect(ChromeStore.identifier(in: "https://chromewebstore.google.com/detail/bitwarden-password-manage/\(id)?hl=es") == id)
        #expect(ChromeStore.identifier(in: "https://chrome.google.com/webstore/detail/\(id)") == id)
        #expect(ChromeStore.identifier(in: "  \(id) ") == id)
    }

    @Test("un texto cualquiera no se toma por una extensión")
    func rejectsOtherText() {
        #expect(ChromeStore.identifier(in: "bitwarden") == nil)
        #expect(ChromeStore.identifier(in: "https://example.com/detail/algo/1234") == nil)
        #expect(ChromeStore.identifier(in: "https://chromewebstore.google.com/detail/x/NNGCECKBAPEBFIMNLNIIIAHKANDCLBLZ") == nil)
    }

    @Test("la descarga se pide a la tienda por el identificador")
    func buildsTheDownloadAddress() {
        let url = ChromeStore.download(id)
        #expect(url.host() == "clients2.google.com")
        #expect(url.absoluteString.contains("id%3D\(id)%26uc"))
        #expect(url.absoluteString.contains("acceptformat=crx3"))
    }

    @Test("del paquete de la tienda se saca el zip que lleva dentro, saltando su cabecera firmada")
    func unwrapsThePackage() {
        let zip = Data("PK\u{3}\u{4}contenido".utf8)
        let header = Data([1, 2, 3, 4, 5])
        let package = Data("Cr24".utf8) + Data([3, 0, 0, 0]) + Data([5, 0, 0, 0]) + header + zip
        #expect(ChromeStore.archive(in: package) == zip)
    }

    @Test("lo que no es un paquete de la tienda se rechaza en vez de descomprimirse a ciegas")
    func rejectsWhatIsNotAPackage() {
        #expect(ChromeStore.archive(in: Data("<html>no encontrado</html>".utf8)) == nil)
        #expect(ChromeStore.archive(in: Data("Cr24".utf8) + Data([3, 0, 0, 0]) + Data([200, 0, 0, 0]) + Data([1])) == nil)
        #expect(ChromeStore.archive(in: Data("Cr24".utf8) + Data([3, 0, 0, 0]) + Data([1, 0, 0, 0]) + Data([9]) + Data("no es zip".utf8)) == nil)
    }
}
