import Testing
@testable import NadaCore

@Suite("La configuración se escribe como la de Ghostty: mismas reglas y, donde aplica, las mismas claves")
struct ConfigTests {
    @Test("cada línea es clave = valor; los espacios, las comillas y las líneas de comentario no cuentan")
    func syntaxFollowsGhostty() {
        let config = Config(text: """
        # mi configuración

        theme=TokyoNight
        font-family = "MonoLisa"
        """)
        #expect(config.string("theme") == "TokyoNight")
        #expect(config.fontFamily == "MonoLisa")
        #expect(config.errors.isEmpty)
    }

    @Test("un valor vacío devuelve la opción a su valor de fábrica")
    func emptyValueResets() {
        let config = Config(text: "unfocused-split-opacity = 0.4\nunfocused-split-opacity =")
        #expect(config.unfocusedSplitOpacity == 0.7)
    }

    @Test("sin configurar nada los valores son los de Ghostty")
    func defaultsMatchGhostty() {
        let config = Config(text: "")
        #expect(config.unfocusedSplitOpacity == 0.7)
        #expect(config.preservesZoomOnNavigation == false)
        #expect(config.restoresWindows)
        #expect(config.startsFullscreen == false)
        #expect(config.fontFamily == nil)
        #expect(config.theme.name(dark: true) == "nada")
    }

    @Test("los paneles sin foco, el divisor y la ampliación se ajustan con las claves de Ghostty")
    func splitOptions() {
        let config = Config(text: """
        unfocused-split-opacity = 0.5
        unfocused-split-fill = #000000
        split-divider-color = #ff0000
        split-preserve-zoom = navigation
        """)
        #expect(config.unfocusedSplitOpacity == 0.5)
        #expect(config.unfocusedSplitFill?.hex == "#000000")
        #expect(config.splitDividerColor?.hex == "#ff0000")
        #expect(config.preservesZoomOnNavigation)
        #expect(Config(text: "split-preserve-zoom = no-navigation").preservesZoomOnNavigation == false)
    }

    @Test("la opacidad se mantiene en el rango que admite Ghostty, para que un panel no desaparezca")
    func opacityIsClamped() {
        #expect(Config(text: "unfocused-split-opacity = 0").unfocusedSplitOpacity == 0.15)
        #expect(Config(text: "unfocused-split-opacity = 3").unfocusedSplitOpacity == 1)
    }

    @Test("fondo y texto escritos a mano mandan sobre los del tema")
    func colorsOverrideTheTheme() {
        let config = Config(text: "background = #101010\nforeground = #fafafa")
        #expect(config.background?.hex == "#101010")
        #expect(config.foreground?.hex == "#fafafa")
    }

    @Test("la ventana puede arrancar a pantalla completa o maximizada y decidir si recupera las pestañas")
    func windowOptions() {
        let config = Config(text: "fullscreen = true\nmaximize = true\nwindow-save-state = never")
        #expect(config.startsFullscreen)
        #expect(config.startsMaximized)
        #expect(config.restoresWindows == false)
    }

    @Test("los atajos salen de las líneas keybind, y keybind = clear quita los de fábrica")
    func keybindsComeFromConfig() {
        let config = Config(text: "keybind = ctrl+h=focus_left")
        #expect(config.keyBindings.action(for: KeyCombo("ctrl+h")!) == .focusPane(.left))
        #expect(config.keyBindings.action(for: KeyCombo("cmd+t")!) == .newTab)
        let cleared = Config(text: "keybind = clear\nkeybind = cmd+t=new_tab")
        #expect(cleared.keyBindings.bindings.count == 1)
    }

    @Test("config-file incluye otro archivo al final, y con ? delante no pasa nada si falta")
    func includesOtherFiles() {
        let files = ["extra": "theme = Nord\nfullscreen = true"]
        let config = Config(text: "config-file = extra\ntheme = TokyoNight\nconfig-file = ?ausente", include: { files[$0] })
        #expect(config.string("theme") == "Nord")
        #expect(config.startsFullscreen)
        #expect(config.errors.isEmpty)
        #expect(Config(text: "config-file = ausente", include: { files[$0] }).errors == ["línea 1: no se puede leer «ausente»"])
    }

    @Test("un archivo que se incluye a sí mismo no cuelga el arranque")
    func includeCyclesAreCut() {
        let files = ["a": "config-file = a\ntheme = Nord"]
        let config = Config(text: "config-file = a", include: { files[$0] })
        #expect(config.string("theme") == "Nord")
    }

    @Test("una clave que no existe o un valor imposible se avisan con su línea, y lo demás sigue valiendo")
    func mistakesAreReported() {
        let config = Config(text: """
        tema = oscuro
        unfocused-split-opacity = mucho
        sin igual
        theme = Nord
        keybind = ctrl+j=volar
        """)
        #expect(config.string("theme") == "Nord")
        #expect(config.errors == [
            "línea 1: opción desconocida «tema»",
            "línea 3: falta «=»",
            "línea 2: «mucho» no vale para unfocused-split-opacity",
            "línea 5: orden desconocida «volar»",
        ])
    }

    @Test("recargar la configuración tiene orden y atajo, como en Ghostty")
    func reloadIsBound() {
        #expect(Config(text: "").keyBindings.action(for: KeyCombo("cmd+shift+,")!) == .reloadConfig)
    }

    @Test("la plantilla documenta todas las opciones sin activar ninguna")
    func templateDocumentsEveryOption() {
        for key in Config.keys {
            #expect(Config.template.contains("# \(key) ="))
        }
        let config = Config(text: Config.template)
        #expect(config.errors.isEmpty)
        #expect(config.entries.isEmpty)
    }
}
