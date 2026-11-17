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

    @Test("un módulo añade sus órdenes a la paleta sin que la paleta lo conozca")
    func moduleCommandsAreListedAndSearchable() {
        let command = ModuleCommand(id: "adblock.toggle", title: "Desactivar bloqueo de anuncios")
        let all = Palette.items(query: "", tabTitles: ["Docs"], moduleCommands: [command])
        #expect(all.contains { $0.action == .module("adblock.toggle") })
        #expect(all.last?.action == .selectTab(0))
        let found = Palette.items(query: "bloqueo", tabTitles: [], moduleCommands: [command])
        #expect(found.first?.action == .module("adblock.toggle"))
    }

    @Test("los ajustes se abren desde la paleta además de con su atajo")
    func settingsAreReachableFromThePalette() {
        #expect(Palette.items(query: "ajustes", tabTitles: []).first?.action == .openSettings)
    }

    @Test("buscar desde la paleta usa el buscador elegido")
    func paletteSearchUsesTheChosenEngine() {
        let items = Palette.items(query: "receta paella", tabTitles: [], searchEngine: .google)
        #expect(items.last?.action == .open(URL(string: "https://www.google.com/search?q=receta%20paella")!))
    }

    @Test("cada ajuste muestra su valor actual para saber qué cambiará al pulsar intro")
    func settingsShowTheirCurrentValue() {
        let settings = [
            Setting(id: "search.engine", title: "Buscador", value: "DuckDuckGo"),
            Setting(id: "adblock.enabled", title: "Bloqueo de anuncios", value: "Activado"),
        ]
        let all = Palette.settingsItems(query: "", settings: settings)
        #expect(all.map(\.shortcut) == ["DuckDuckGo", "Activado"])
        let found = Palette.settingsItems(query: "bloq", settings: settings)
        #expect(found.map(\.action) == [.changeSetting("adblock.enabled")])
    }

    @Test("dividir la pestaña también se puede lanzar desde la paleta")
    func splitsAreReachableFromThePalette() {
        #expect(Palette.items(query: "dividir a la derecha", tabTitles: []).first?.action == .split(.horizontal))
        #expect(Palette.items(query: "dividir abajo", tabTitles: []).first?.action == .split(.vertical))
    }

    @Test("buscar en la página ofrece ir a la siguiente coincidencia con intro y a la anterior debajo")
    func findOffersNextAndPrevious() {
        #expect(Palette.findItems(query: "  ").isEmpty)
        let items = Palette.findItems(query: "paella")
        #expect(items.map(\.action) == [.find("paella", backwards: false), .find("paella", backwards: true)])
    }

    @Test("solo las nueve primeras pestañas anuncian atajo porque no hay ⌘10")
    func onlyFirstNineTabsShowShortcut() {
        let items = Palette.items(query: "", tabTitles: Array(repeating: "t", count: 10))
        #expect(items.first { $0.action == .selectTab(8) }?.shortcut == "⌘9")
        #expect(items.first { $0.action == .selectTab(9) }?.shortcut == "")
    }
}
