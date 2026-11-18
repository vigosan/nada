import Testing
@testable import NadaCore

@Suite("El tema viste el navegador con los mismos archivos y la misma sintaxis que Ghostty")
struct ThemeTests {
    private let tokyoNight = """
    palette = 0=#15161e
    palette = 4=#7aa2f7
    background = #1a1b26
    foreground = #c0caf5
    cursor-color = #c0caf5
    """

    @Test("sin configurar nada hay un tema claro y otro oscuro que siguen al sistema")
    func defaultFollowsTheSystem() {
        let choice = ThemeChoice(config: "keybind = cmd+d=split_right")
        #expect(choice.name(dark: true) == "nada")
        #expect(choice.name(dark: false) == "nada-light")
    }

    @Test("un solo nombre se usa siempre, y light y dark eligen según el sistema, como en Ghostty")
    func choiceAcceptsOneOrTwoThemes() {
        let single = ThemeChoice(config: "theme = TokyoNight")
        #expect(single.name(dark: true) == "TokyoNight")
        #expect(single.name(dark: false) == "TokyoNight")
        let pair = ThemeChoice(config: "theme = dark:TokyoNight, light:TokyoNight Day")
        #expect(pair.name(dark: true) == "TokyoNight")
        #expect(pair.name(dark: false) == "TokyoNight Day")
    }

    @Test("un tema de Ghostty da el fondo, el texto y el azul de su paleta como color de acento")
    func ghosttyThemeIsRead() throws {
        let theme = try #require(ThemeColors(ghostty: tokyoNight))
        #expect(theme.background.hex == "#1a1b26")
        #expect(theme.foreground.hex == "#c0caf5")
        #expect(theme.accent.hex == "#7aa2f7")
        #expect(theme.isDark)
    }

    @Test("los tonos intermedios se sacan del fondo y del texto, para que cualquier tema tenga barras y bordes legibles")
    func surfacesAreDerived() throws {
        let theme = try #require(ThemeColors(ghostty: tokyoNight))
        #expect(theme.bar.luminance > theme.background.luminance)
        #expect(theme.raised.luminance > theme.bar.luminance)
        #expect(theme.dim.luminance < theme.foreground.luminance)
        #expect(theme.dim.luminance > theme.raised.luminance)
    }

    @Test("un tema claro se reconoce por su fondo, y sus barras se oscurecen en vez de aclararse")
    func lightThemesAreDetected() throws {
        let theme = try #require(ThemeColors(ghostty: "background = #ffffff\nforeground = #1f2328\npalette = 4=#0969da"))
        #expect(!theme.isDark)
        #expect(theme.bar.luminance < theme.background.luminance)
    }

    @Test("un archivo que no trae fondo y texto no es un tema, y se avisa en vez de pintar a medias")
    func incompleteThemesAreRejected() {
        #expect(ThemeColors(ghostty: "palette = 4=#7aa2f7") == nil)
        #expect(ThemeColors(ghostty: "background = nope\nforeground = #ffffff") == nil)
    }

    @Test("los dos temas propios son temas válidos, uno oscuro y otro claro")
    func builtInThemesAreValid() throws {
        #expect(try #require(ThemeColors(ghostty: ThemeColors.builtIn["nada"] ?? "")).isDark)
        #expect(try #require(ThemeColors(ghostty: ThemeColors.builtIn["nada-light"] ?? "")).isDark == false)
    }
}
