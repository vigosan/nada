import Foundation
import CoreGraphics
import Testing
@testable import NadaCore

@Suite("Los paneles se reparten la pestaña y el foco va a donde apunta la flecha")
struct PaneLayoutTests {
    @Test("una pestaña empieza con un único panel que la ocupa entera")
    func startsWithOnePane() {
        let layout = PaneLayout()
        #expect(layout.frames == [0: CGRect(x: 0, y: 0, width: 1, height: 1)])
        #expect(layout.focused == 0)
    }

    @Test("dividir a la derecha parte el panel con foco y enfoca el nuevo para usarlo ya")
    func splitRightHalvesTheFocusedPane() {
        var layout = PaneLayout()
        let new = layout.split(.horizontal)
        #expect(layout.frames[0] == CGRect(x: 0, y: 0, width: 0.5, height: 1))
        #expect(layout.frames[new] == CGRect(x: 0.5, y: 0, width: 0.5, height: 1))
        #expect(layout.focused == new)
    }

    @Test("dividir abajo solo parte el panel con foco, no toda la pestaña")
    func splitDownOnlyAffectsTheFocusedPane() {
        var layout = PaneLayout()
        let right = layout.split(.horizontal)
        let bottom = layout.split(.vertical)
        #expect(layout.frames[0] == CGRect(x: 0, y: 0, width: 0.5, height: 1))
        #expect(layout.frames[right] == CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5))
        #expect(layout.frames[bottom] == CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5))
    }

    @Test("la flecha lleva el foco al panel que está pegado en esa dirección")
    func focusMovesToTheAdjacentPane() {
        var layout = PaneLayout()
        let right = layout.split(.horizontal)
        let bottom = layout.split(.vertical)
        layout.moveFocus(.up)
        #expect(layout.focused == right)
        layout.moveFocus(.left)
        #expect(layout.focused == 0)
        layout.moveFocus(.right)
        #expect(layout.focused == right)
        layout.moveFocus(.down)
        #expect(layout.focused == bottom)
    }

    @Test("contra el borde de la ventana el foco no se mueve ni se pierde")
    func focusStaysAtTheEdge() {
        var layout = PaneLayout()
        let right = layout.split(.horizontal)
        layout.moveFocus(.right)
        layout.moveFocus(.up)
        #expect(layout.focused == right)
    }

    @Test("al cerrar un panel su vecino recupera el espacio y el foco")
    func closingGivesSpaceAndFocusToTheSibling() {
        var layout = PaneLayout()
        let right = layout.split(.horizontal)
        _ = layout.split(.vertical)
        #expect(layout.closeFocused() == true)
        #expect(layout.frames[right] == CGRect(x: 0.5, y: 0, width: 0.5, height: 1))
        #expect(layout.focused == right)
    }

    @Test("el último panel no se cierra aquí porque cerrarlo es cerrar la pestaña")
    func lastPaneIsNotClosed() {
        var layout = PaneLayout()
        #expect(layout.closeFocused() == false)
        #expect(layout.frames.count == 1)
    }

    @Test("redimensionar mueve el divisor hacia la flecha, esté el foco a un lado o al otro")
    func resizingMovesTheDivider() {
        var layout = PaneLayout()
        let right = layout.split(.horizontal)
        layout.resize(.right)
        #expect(abs(layout.frames[0]!.width - 0.55) < 0.0001)
        #expect(abs(layout.frames[right]!.minX - 0.55) < 0.0001)
        layout.focus(0)
        layout.resize(.left)
        layout.resize(.left)
        #expect(abs(layout.frames[0]!.width - 0.45) < 0.0001)
    }

    @Test("redimensionar en vertical no toca un divisor horizontal")
    func resizingIgnoresSplitsOnTheOtherAxis() {
        var layout = PaneLayout()
        _ = layout.split(.horizontal)
        layout.resize(.down)
        #expect(layout.frames[0]!.width == 0.5)
    }

    @Test("un panel nunca se encoge hasta desaparecer")
    func resizingStopsBeforeAPaneVanishes() {
        var layout = PaneLayout()
        _ = layout.split(.horizontal)
        for _ in 0..<40 { layout.resize(.left) }
        #expect(layout.frames[0]!.width >= 0.1)
    }

    @Test("ampliar deja solo el panel con foco a pantalla entera y volver a pulsar lo restaura")
    func zoomShowsOnlyTheFocusedPane() {
        var layout = PaneLayout()
        let right = layout.split(.horizontal)
        layout.toggleZoom()
        #expect(layout.frames == [right: CGRect(x: 0, y: 0, width: 1, height: 1)])
        layout.toggleZoom()
        #expect(layout.frames.count == 2)
        #expect(layout.frames[right] == CGRect(x: 0.5, y: 0, width: 0.5, height: 1))
    }

    @Test("de fábrica, cambiar de panel deshace la ampliación, como en Ghostty")
    func navigatingLeavesZoomByDefault() {
        var layout = PaneLayout()
        _ = layout.split(.horizontal)
        layout.toggleZoom()
        layout.moveFocus(.left)
        #expect(layout.frames.count == 2)
        layout.toggleZoom()
        layout.focusNext()
        #expect(layout.frames.count == 2)
    }

    @Test("con split-preserve-zoom, al cambiar de panel pasas al siguiente a pantalla entera")
    func navigatingKeepsZoomWhenAsked() {
        var layout = PaneLayout()
        layout.preservesZoom = true
        let right = layout.split(.horizontal)
        layout.toggleZoom()
        layout.moveFocus(.left)
        #expect(layout.frames == [0: CGRect(x: 0, y: 0, width: 1, height: 1)])
        layout.focusNext()
        #expect(layout.frames == [right: CGRect(x: 0, y: 0, width: 1, height: 1)])
    }

    @Test("dividir o cerrar un panel sí deshace la ampliación, porque cambia lo que hay que ver")
    func changingTheLayoutLeavesZoom() {
        var layout = PaneLayout()
        _ = layout.split(.horizontal)
        layout.toggleZoom()
        _ = layout.split(.vertical)
        #expect(layout.frames.count == 3)
        layout.toggleZoom()
        #expect(layout.closeFocused() == true)
        #expect(layout.frames.count == 2)
    }

    @Test("igualar reparte el espacio entre todos los paneles de una fila, no solo entre dos mitades")
    func equalizeSharesSpaceEvenly() {
        var layout = PaneLayout()
        let middle = layout.split(.horizontal)
        let right = layout.split(.horizontal)
        layout.resize(.right)
        layout.equalize()
        for id in [0, middle, right] {
            #expect(abs(layout.frames[id]!.width - 1.0 / 3.0) < 0.0001)
        }
    }

    @Test("igualar no deja que un panel partido en vertical cuente doble en su fila")
    func equalizeTreatsAStackAsOneColumn() {
        var layout = PaneLayout()
        let right = layout.split(.horizontal)
        let bottom = layout.split(.vertical)
        layout.resize(.left)
        layout.resize(.down)
        layout.equalize()
        #expect(layout.frames[0]!.width == 0.5)
        #expect(layout.frames[right]!.height == 0.5)
        #expect(layout.frames[bottom]!.height == 0.5)
    }

    @Test("panel siguiente y anterior recorren todos en orden de lectura y dan la vuelta")
    func cyclingVisitsEveryPane() {
        var layout = PaneLayout()
        let right = layout.split(.horizontal)
        let bottom = layout.split(.vertical)
        layout.focusNext()
        #expect(layout.focused == 0)
        layout.focusNext()
        #expect(layout.focused == right)
        layout.focusPrevious()
        #expect(layout.focused == 0)
        layout.focusPrevious()
        #expect(layout.focused == bottom)
    }

    @Test("un clic en otro panel le da el foco")
    func focusCanBeSetDirectly() {
        var layout = PaneLayout()
        _ = layout.split(.horizontal)
        layout.focus(0)
        #expect(layout.focused == 0)
        layout.focus(99)
        #expect(layout.focused == 0)
    }

    @Test("un reparto de paneles guardado vuelve con los mismos huecos, el mismo foco y sin repetir identificadores al seguir dividiendo")
    func layoutSurvivesARoundTrip() throws {
        var layout = PaneLayout()
        _ = layout.split(.horizontal)
        let third = layout.split(.vertical)
        layout.resize(.left)
        var restored = try JSONDecoder().decode(PaneLayout.self, from: JSONEncoder().encode(layout))
        #expect(restored.frames == layout.frames)
        #expect(restored.focused == third)
        #expect(restored.split(.horizontal) == layout.split(.horizontal))
    }

    @Test("un panel ampliado se guarda sin ampliar, para no esconder los demás al volver")
    func zoomIsNotRestored() throws {
        var layout = PaneLayout()
        _ = layout.split(.horizontal)
        layout.toggleZoom()
        let restored = try JSONDecoder().decode(PaneLayout.self, from: JSONEncoder().encode(layout))
        #expect(restored.frames.count == 2)
    }
}
