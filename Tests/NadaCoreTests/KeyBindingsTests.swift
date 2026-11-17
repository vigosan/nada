import Testing
@testable import NadaCore

@Suite("Los atajos son de quien usa el navegador, no del navegador")
struct KeyBindingsTests {
    @Test("sin configuración los atajos son los de Ghostty para no reaprender nada")
    func defaultsFollowGhostty() {
        let bindings = KeyBindings(config: "")
        #expect(bindings.label(for: .split(.horizontal)) == "⌘D")
        #expect(bindings.label(for: .split(.vertical)) == "⇧⌘D")
        #expect(bindings.label(for: .focusPane(.left)) == "⌥⌘←")
        #expect(bindings.label(for: .resizePane(.down)) == "⌃⌘↓")
        #expect(bindings.label(for: .selectTab(2)) == "⌘3")
        #expect(bindings.errors.isEmpty)
    }

    @Test("pantalla completa y ampliar panel usan intro como en Ghostty")
    func returnKeyBindings() {
        let bindings = KeyBindings(config: "")
        #expect(bindings.label(for: .toggleFullscreen) == "⌘↩")
        #expect(bindings.label(for: .zoomPane) == "⇧⌘↩")
        #expect(KeyCombo("cmd+enter") == KeyCombo("cmd+return"))
    }

    @Test("los atajos de navegador más usados vienen de fábrica")
    func browsingDefaults() {
        let bindings = KeyBindings(config: "")
        #expect(bindings.label(for: .nextTab) == "⌃⇥")
        #expect(bindings.label(for: .previousTab) == "⌃⇧⇥")
        #expect(bindings.label(for: .equalizePanes) == "⌃⌘=")
        #expect(bindings.label(for: .reopenTab) == "⇧⌘T")
        #expect(bindings.label(for: .zoomIn) == "⌘+")
        #expect(bindings.label(for: .startFind) == "⌘F")
        #expect(bindings.action(for: KeyCombo("cmd+g")!) == .findNext)
        #expect(bindings.errors.isEmpty)
    }

    @Test("la tecla igual se puede reasignar aunque también separe la orden")
    func equalsKeyCanBeBound() {
        let bindings = KeyBindings(config: "keybind = cmd+opt+==zoom_in")
        #expect(bindings.action(for: KeyCombo("cmd+opt+=")!) == .zoomIn)
        #expect(bindings.errors.isEmpty)
    }

    @Test("una línea keybind añade un atajo propio y la paleta lo anuncia")
    func configAddsABinding() {
        let bindings = KeyBindings(config: "keybind = ctrl+h=focus_left")
        #expect(bindings.action(for: KeyCombo("ctrl+h")!) == .focusPane(.left))
        #expect(bindings.label(for: .focusPane(.left)) == "⌃H")
        let items = Palette.items(query: "dividir a la derecha", tabTitles: [], bindings: KeyBindings(config: "keybind = ctrl+shift+v=split_right"))
        #expect(items.first?.shortcut == "⌃⇧V")
    }

    @Test("reutilizar una combinación se la quita a la orden que la tenía para que no haya dos respuestas")
    func reusingAComboReplacesItsAction() {
        let bindings = KeyBindings(config: "keybind = cmd+d=new_tab")
        #expect(bindings.action(for: KeyCombo("cmd+d")!) == .newTab)
        #expect(bindings.label(for: .split(.horizontal)) == "")
    }

    @Test("unbind libera una combinación que estorba")
    func unbindRemovesABinding() {
        let bindings = KeyBindings(config: "keybind = cmd+w=unbind")
        #expect(bindings.action(for: KeyCombo("cmd+w")!) == nil)
    }

    @Test("las pestañas se alcanzan por número con goto_tab")
    func gotoTabTakesANumber() {
        let bindings = KeyBindings(config: "keybind = opt+3=goto_tab:3")
        #expect(bindings.action(for: KeyCombo("opt+3")!) == .selectTab(2))
    }

    @Test("los sinónimos de los modificadores y su orden no importan")
    func modifierNamesAreFlexible() {
        #expect(KeyCombo("shift+cmd+d") == KeyCombo("command+shift+D"))
        #expect(KeyCombo("alt+left") == KeyCombo("option+left"))
        #expect(KeyCombo("cmd+,")?.label == "⌘,")
    }

    @Test("una línea mal escrita se avisa con su número y no estropea las demás")
    func invalidLinesAreReportedAndSkipped() {
        let config = """
        # mis atajos

        keybind = ctrl+h=focus_left
        keybind = ctrl+j=volar
        keybind = hyper+x=reload
        theme = dark
        """
        let bindings = KeyBindings(config: config)
        #expect(bindings.action(for: KeyCombo("ctrl+h")!) == .focusPane(.left))
        #expect(bindings.errors == ["línea 4: orden desconocida «volar»", "línea 5: combinación no válida «hyper+x»"])
    }
}
