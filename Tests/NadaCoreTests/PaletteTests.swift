import Foundation
import Testing
@testable import NadaCore

@Suite("La paleta pone primero lo que la persona quiere hacer al pulsar intro")
struct PaletteTests {
    @Test("vacía enseña primero las pestañas abiertas, que es a lo que más se va, y después las órdenes")
    func emptyQueryStartsWithOpenTabs() {
        let items = Palette.items(query: "", tabTitles: ["Docs", "Correo"])
        #expect(items.prefix(2).map(\.action) == [.selectTab(0), .selectTab(1)])
        #expect(items.map(\.action).contains(.newTab))
        #expect(items.map(\.action).contains(.toggleDevTools))
    }

    @Test("la pestaña en la que ya estás no se ofrece: ir a ella no hace nada")
    func currentTabIsNotOffered() {
        let items = Palette.items(query: "", tabTitles: ["Docs", "Correo"], activeTab: 0)
        #expect(items.first?.action == .selectTab(1))
        #expect(!items.map(\.action).contains(.selectTab(0)))
    }

    @Test("lo que solo tiene sentido como atajo no ocupa sitio en la paleta")
    func shortcutOnlyCommandsStayOutOfThePalette() {
        let actions = Palette.items(query: "", tabTitles: []).map(\.action)
        for direction in [Direction.left, .right, .up, .down] {
            #expect(!actions.contains(.focusPane(direction)))
            #expect(!actions.contains(.resizePane(direction)))
        }
        #expect(!actions.contains(.togglePalette))
    }

    @Test("la dirección de la página se copia y se edita desde la paleta, porque la barra de pestañas solo la enseña")
    func addressActionsAreInThePalette() {
        let items = Palette.items(query: "", tabTitles: [])
        let copy = items.first { $0.action == .copyAddress }
        #expect(copy?.title == "Copiar dirección")
        #expect(copy?.shortcut == "⇧⌘C")
        #expect(items.contains { $0.action == .openLocation && $0.shortcut == "⌘L" })
        #expect(Palette.items(query: "copiar dir", tabTitles: []).first?.action == .copyAddress)
    }

    @Test("el vídeo se lleva a toda la ventana desde la paleta y con su atajo, porque YouTube solo ofrece modo cine o pantalla completa")
    func videoFillIsInThePalette() {
        let fill = Palette.items(query: "", tabTitles: []).first { $0.action == .fillVideo }
        #expect(fill?.title == "Vídeo a toda la ventana")
        #expect(fill?.shortcut == "⇧⌘F")
        #expect(Palette.items(query: "video a toda", tabTitles: []).first?.action == .fillVideo)
    }

    @Test("el vídeo sale a flotar desde la paleta y con su atajo, para seguir viéndolo mientras se trabaja en otra app")
    func pictureInPictureIsInThePalette() {
        let float = Palette.items(query: "", tabTitles: []).first { $0.action == .pictureInPicture }
        #expect(float?.title == "Vídeo flotante")
        #expect(float?.shortcut == "⌥⌘P")
        #expect(Palette.items(query: "video flot", tabTitles: []).first?.action == .pictureInPicture)
    }

    @Test("la velocidad del vídeo se cambia desde la paleta y con atajos que no chocan con los de YouTube")
    func playbackSpeedIsInThePalette() {
        let items = Palette.items(query: "", tabTitles: [])
        #expect(items.first { $0.action == .playbackSpeed(faster: true) }?.title == "Acelerar vídeo")
        #expect(items.first { $0.action == .playbackSpeed(faster: true) }?.shortcut == "⌥⌘.")
        #expect(items.first { $0.action == .playbackSpeed(faster: false) }?.title == "Frenar vídeo")
        #expect(items.first { $0.action == .playbackSpeed(faster: false) }?.shortcut == "⌥⌘,")
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
        #expect(all.first?.action == .selectTab(0))
        let found = Palette.items(query: "bloqueo", tabTitles: [], moduleCommands: [command])
        #expect(found.first?.action == .module("adblock.toggle"))
    }

    @Test("la orden de un módulo enseña su atajo, que es como se aprende el de una extensión sin abrir sus ajustes")
    func moduleCommandsShowTheirShortcut() {
        let command = ModuleCommand(id: "extension.command:bitwarden:autofill_login", title: "Bitwarden: Autofill", shortcut: "⇧⌘L")
        let found = Palette.items(query: "autofill", tabTitles: [], moduleCommands: [command])
        #expect(found.first?.shortcut == "⇧⌘L")
        #expect(Palette.items(query: "x", tabTitles: [], moduleCommands: [ModuleCommand(id: "x", title: "x")]).first?.shortcut == "")
    }

    @Test("cerrar todas las sesiones y borrar lo que los sitios guardan se hace desde la paleta, porque no hay ventana de ajustes")
    func siteDataIsClearedFromThePalette() {
        #expect(Palette.items(query: "borrar cookies", tabTitles: []).first?.action == .clearSiteData)
    }

    @Test("hacer de Nada el navegador por defecto se pide desde la paleta, sin ir a Ajustes del Sistema")
    func defaultBrowserIsSetFromThePalette() {
        #expect(Palette.items(query: "navegador por defecto", tabTitles: []).first?.action == .makeDefaultBrowser)
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
        #expect(all.prefix(2).map(\.shortcut) == ["DuckDuckGo", "Activado"])
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

    @Test("la raíz de los ajustes solo tiene los ajustes generales y la entrada a cada sección, para no enterrarlos entre atajos")
    func settingsRootStaysShort() {
        let settings = [Setting(id: "search.engine", title: "Buscador", value: "DuckDuckGo")]
        let root = Palette.settingsItems(query: "", settings: settings)
        #expect(root.map(\.action) == [.changeSetting("search.engine"), .openSettingsSection(.shortcuts)])
        #expect(root.last?.shortcut == "›")
    }

    @Test("la sección de atajos se reparte en grupos, para no recorrer cuarenta filas buscando una")
    func shortcutsSectionIsSplitIntoGroups() {
        let items = Palette.settingsItems(query: "", settings: [], section: .shortcuts)
        #expect(items.map(\.action) == [
            .editKeyBindings,
            .openSettingsSection(.shortcutGroup(.page)),
            .openSettingsSection(.shortcutGroup(.tabs)),
            .openSettingsSection(.shortcutGroup(.panes)),
            .openSettingsSection(.shortcutGroup(.window)),
        ])
        #expect(items.map(\.title).dropFirst() == ["Página", "Pestañas", "Paneles", "Ventana"])
    }

    @Test("cada grupo enseña sus órdenes con la tecla actual, y ninguna orden se queda sin grupo")
    func groupsListTheirShortcuts() {
        let bindings = KeyBindings(config: "keybind = ctrl+h=focus_left")
        let panes = Palette.settingsItems(query: "", settings: [], bindings: bindings, section: .shortcutGroup(.panes))
        #expect(panes.first { $0.title == "Ir al panel de la izquierda" }?.shortcut == "⌃H")
        #expect(panes.contains { $0.title == "Recargar" } == false)
        let total = CommandGroup.allCases.map {
            Palette.settingsItems(query: "", settings: [], section: .shortcutGroup($0)).count
        }.reduce(0, +)
        #expect(total == Command.all.count)
    }

    @Test("escape sube un nivel cada vez hasta la raíz")
    func sectionsKnowTheirParent() {
        #expect(SettingsSection.shortcutGroup(.panes).parent == .shortcuts)
        #expect(SettingsSection.shortcuts.parent == nil)
        #expect(SettingsSection.shortcutGroup(.panes).path == "Ajustes › Atajos de teclado › Paneles")
    }

    @Test("buscar dentro de atajos encuentra una orden de cualquier grupo")
    func shortcutsSearchCrossesGroups() {
        let found = Palette.settingsItems(query: "igualar", settings: [], section: .shortcuts)
        #expect(found.map(\.title) == ["Igualar paneles"])
    }

    @Test("buscar desde la raíz también encuentra atajos, sin tener que entrar antes en su sección")
    func rootSearchReachesIntoSections() {
        let found = Palette.settingsItems(query: "dividir abajo", settings: [])
        #expect(found.map(\.title) == ["Dividir abajo"])
    }

    @Test("la lista se desplaza con la selección, así se llega a cualquier fila aunque no quepan todas")
    func listWindowFollowsTheSelection() {
        #expect(Palette.window(selected: 0, count: 30, size: 9) == 0..<9)
        #expect(Palette.window(selected: 12, count: 30, size: 9) == 8..<17)
        #expect(Palette.window(selected: 29, count: 30, size: 9) == 21..<30)
        #expect(Palette.window(selected: 2, count: 3, size: 9) == 0..<3)
    }

    @Test("solo las nueve primeras pestañas anuncian atajo porque no hay ⌘10")
    func onlyFirstNineTabsShowShortcut() {
        let items = Palette.items(query: "", tabTitles: Array(repeating: "t", count: 10))
        #expect(items.first { $0.action == .selectTab(8) }?.shortcut == "⌘9")
        #expect(items.first { $0.action == .selectTab(9) }?.shortcut == "")
    }
}
