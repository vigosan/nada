import Foundation
import Testing
@testable import NoBrowserCore

@Suite("La paleta pone primero lo que la persona quiere hacer al pulsar intro")
struct PaletteTests {
    @Test("vacía muestra todas las órdenes y las pestañas abiertas para descubrirlas")
    func emptyQueryListsEverything() {
        let items = Palette.items(query: "", tabTitles: ["Docs"])
        #expect(items.map(\.action).contains(.newTab))
        #expect(items.map(\.action).contains(.toggleDevTools))
        #expect(items.last?.action == .selectTab(0))
    }

    @Test("una dirección se abre con intro aunque también coincida con una orden")
    func addressComesFirst() {
        let items = Palette.items(query: "example.com", tabTitles: ["example.com"])
        #expect(items.first?.action == .open(URL(string: "https://example.com")!))
        #expect(items.contains { $0.action == .selectTab(0) })
    }

    @Test("un texto que coincide con una orden la ejecuta antes que buscarlo en la web")
    func commandBeatsSearch() {
        let items = Palette.items(query: "recar", tabTitles: [])
        #expect(items.first?.action == .reload)
        #expect(items.last?.action == .open(AddressResolver.url(for: "recar")!))
    }

    @Test("se encuentra una orden sin escribir tildes ni mayúsculas")
    func matchingIgnoresCaseAndAccents() {
        #expect(Palette.items(query: "PESTANA nueva", tabTitles: []).first?.action == .newTab)
    }

    @Test("un texto que no coincide con nada sigue sirviendo para buscar")
    func unmatchedTextStillSearches() {
        let items = Palette.items(query: "receta paella", tabTitles: [])
        #expect(items.map(\.action) == [.open(AddressResolver.url(for: "receta paella")!)])
    }

    @Test("solo las nueve primeras pestañas anuncian atajo porque no hay ⌘10")
    func onlyFirstNineTabsShowShortcut() {
        let items = Palette.items(query: "", tabTitles: Array(repeating: "t", count: 10))
        #expect(items.first { $0.action == .selectTab(8) }?.shortcut == "⌘9")
        #expect(items.first { $0.action == .selectTab(9) }?.shortcut == "")
    }
}
