import Foundation
import Testing
@testable import NadaCore

@Suite("Nada se maneja desde la terminal, para que un script o un agente use el navegador que ya tienes abierto")
struct RemoteTests {
    private let folder = "/Users/ana/proyecto"

    @Test("cada orden de la terminal se entiende por su primera palabra")
    func parsesTheCommands() throws {
        #expect(try RemoteRequest(arguments: ["open", "example.com"], folder: folder) == .open("example.com"))
        #expect(try RemoteRequest(arguments: ["tabs"], folder: folder) == .tabs(json: false))
        #expect(try RemoteRequest(arguments: ["tabs", "--json"], folder: folder) == .tabs(json: true))
        #expect(try RemoteRequest(arguments: ["eval", "document.title"], folder: folder) == .eval("document.title"))
        #expect(try RemoteRequest(arguments: ["text"], folder: folder) == .text)
    }

    @Test("lo que se abre puede llevar espacios sin comillas, como una búsqueda escrita de corrido")
    func joinsTheWordsToOpen() throws {
        #expect(try RemoteRequest(arguments: ["open", "swift", "testing"], folder: folder) == .open("swift testing"))
    }

    @Test("la captura se guarda donde está la terminal, no donde arrancó el navegador")
    func resolvesTheScreenshotPath() throws {
        #expect(try RemoteRequest(arguments: ["screenshot", "pr.png"], folder: folder) == .screenshot("/Users/ana/proyecto/pr.png"))
        #expect(try RemoteRequest(arguments: ["screenshot", "/tmp/a.png"], folder: folder) == .screenshot("/tmp/a.png"))
        #expect(try RemoteRequest(arguments: ["screenshot"], folder: folder) == .screenshot("/Users/ana/proyecto/nada.png"))
    }

    @Test("una orden mal escrita explica cómo se usa en vez de hacer otra cosa")
    func rejectsWhatItDoesNotUnderstand() {
        #expect(throws: RemoteUsage.self) { try RemoteRequest(arguments: ["abrir", "x"], folder: folder) }
        #expect(throws: RemoteUsage.self) { try RemoteRequest(arguments: ["open"], folder: folder) }
        #expect(throws: RemoteUsage.self) { try RemoteRequest(arguments: ["eval"], folder: folder) }
        #expect(throws: RemoteUsage.self) { try RemoteRequest(arguments: [], folder: folder) }
        #expect(RemoteUsage().text.contains("nada eval"))
    }

    @Test("solo las palabras que son órdenes se toman por órdenes: macOS arranca las apps con argumentos propios")
    func tellsCommandsFromLaunchArguments() {
        #expect(RemoteRequest.isCommand("tabs"))
        #expect(RemoteRequest.isCommand("help"))
        #expect(!RemoteRequest.isCommand("-NSDocumentRevisionsDebugMode"))
        #expect(!RemoteRequest.isCommand("-psn_0_12345"))
    }

    @Test("la orden y su respuesta viajan en una línea cada una, aunque lleven saltos de línea dentro")
    func travelsAsOneLine() throws {
        let request = RemoteRequest.eval("1 +\n2")
        let line = try request.line()
        #expect(line.last == UInt8(ascii: "\n"))
        #expect(line.dropLast().contains(UInt8(ascii: "\n")) == false)
        #expect(try RemoteRequest(line: line.dropLast()) == request)
        let response = RemoteResponse(ok: false, output: "falló\naquí")
        #expect(try RemoteResponse(line: response.line().dropLast()) == response)
    }

    @Test("las pestañas salen una por línea para leerlas o cortarlas con cut, con la activa marcada")
    func listsTabsAsLines() {
        let tabs = [
            RemoteTab(index: 1, title: "EL PAÍS", url: "https://elpais.com/", active: false),
            RemoteTab(index: 2, title: "Con\ttabulador", url: "https://example.com/", active: true),
        ]
        #expect(RemoteTab.render(tabs, json: false) == "1\t \tEL PAÍS\thttps://elpais.com/\n2\t*\tCon tabulador\thttps://example.com/")
    }

    @Test("con --json las pestañas salen como datos para jq")
    func listsTabsAsJSON() throws {
        let tabs = [RemoteTab(index: 1, title: "EL PAÍS", url: "https://elpais.com/", active: true)]
        let decoded = try JSONDecoder().decode([RemoteTab].self, from: Data(RemoteTab.render(tabs, json: true).utf8))
        #expect(decoded == tabs)
    }

    @Test("el resultado de un script sale como texto si es texto y como JSON si son datos")
    func rendersScriptResults() {
        #expect(RemoteResult.render("hola") == "hola")
        #expect(RemoteResult.render(42) == "42")
        #expect(RemoteResult.render(true) == "true")
        #expect(RemoteResult.render(["a": 1]) == #"{"a":1}"#)
        #expect(RemoteResult.render([1, "dos"]) == #"[1,"dos"]"#)
        #expect(RemoteResult.render(nil) == "")
    }

    @Test("el control desde la terminal viene apagado: deja que cualquier programa tuyo lea las páginas donde tienes sesión")
    func isOffUnlessAsked() {
        #expect(Config(text: "").allowsRemoteControl == false)
        #expect(Config(text: "remote-control = true").allowsRemoteControl)
        #expect(Config(text: "remote-control = quizá").errors.count == 1)
    }
}
