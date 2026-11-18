import Testing
@testable import NadaCore

@Suite("La barra de menús enseña todo lo que el navegador sabe hacer, cada cosa en su sitio")
struct MenuLayoutTests {
    private func commands(in entries: [MenuEntry]) -> [String] {
        entries.flatMap { entry -> [String] in
            switch entry {
            case .command(let name, _): [name]
            case .submenu(_, _, let children): commands(in: children)
            case .system, .separator: []
            }
        }
    }

    @Test("cada orden aparece una sola vez en los menús, así ninguna queda escondida ni duplicada")
    func everyCommandIsPlacedOnce() {
        let placed = MenuLayout.menus.flatMap { commands(in: $0.entries) }
        #expect(placed.sorted() == Command.all.map(\.name).sorted())
    }

    @Test("los menús siguen el orden habitual de una app de Mac, con Ventana y Ayuda al final")
    func menusFollowTheMacOrder() {
        #expect(MenuLayout.menus.map(\.title) == ["Nada", "Archivo", "Edición", "Ver", "Historial", "Ventana", "Ayuda"])
    }

    @Test("moverse entre paneles y cambiar su tamaño van en submenús para no alargar el menú Ventana")
    func paneCommandsAreGrouped() throws {
        let window = try #require(MenuLayout.menus.first { $0.title == "Ventana" })
        let submenus = window.entries.compactMap { entry -> String? in
            if case .submenu(let title, _, _) = entry { return title }
            return nil
        }
        #expect(submenus == ["Ir a la pestaña", "Ir al panel", "Mover divisor"])
    }
}
