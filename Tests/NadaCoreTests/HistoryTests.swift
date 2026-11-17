import Foundation
import Testing
@testable import NadaCore

@Suite("El historial recuerda dónde has estado para que no tengas que escribirlo entero otra vez")
struct HistoryTests {
    private let day: TimeInterval = 86_400

    private func history(_ visits: [(String, String, Int)]) -> History {
        var history = History()
        for (index, (url, title, count)) in visits.enumerated() {
            for visit in 0..<count {
                history.record(url: URL(string: url)!, title: title, at: Date(timeIntervalSince1970: Double(index) * day + Double(visit)), newVisit: true)
            }
        }
        return history
    }

    @Test("volver a una página no la duplica: suma una visita y se queda con el título más reciente")
    func revisitingUpdatesTheSameEntry() {
        var history = History()
        let url = URL(string: "https://elpais.com/")!
        history.record(url: url, title: "Cargando", at: Date(timeIntervalSince1970: 1), newVisit: true)
        history.record(url: url, title: "EL PAÍS", at: Date(timeIntervalSince1970: 2), newVisit: false)
        history.record(url: url, title: "EL PAÍS", at: Date(timeIntervalSince1970: 3), newVisit: true)
        #expect(history.entries.count == 1)
        #expect(history.entries[0].title == "EL PAÍS")
        #expect(history.entries[0].visits == 2)
    }

    @Test("el principio de un sitio visitado lo propone primero, aunque otra página lo mencione más veces")
    func hostPrefixIsAStrongMatch() {
        let history = history([
            ("https://example.org/el-pais-de-nunca-jamas", "Elpa y el país", 9),
            ("https://www.elpais.com/", "EL PAÍS", 1),
        ])
        let matches = history.matches(for: "elp")
        #expect(matches.strong.map(\.url.absoluteString) == ["https://www.elpais.com/"])
        #expect(matches.weak.map(\.url.absoluteString) == ["https://example.org/el-pais-de-nunca-jamas"])
    }

    @Test("las páginas de resultados de un buscador no se proponen: son búsquedas pasadas, no sitios a los que volver")
    func searchResultPagesAreNotSuggested() {
        let history = history([
            ("https://www.google.com/search?sca_esv=1&q=hacker+news", "hacker news - Buscar con Google", 3),
            ("https://duckduckgo.com/?q=google&ia=web", "google at DuckDuckGo", 3),
            ("https://search.brave.com/search?q=google", "google - Brave Search", 3),
            ("https://www.google.com/", "Google", 1),
        ])
        let matches = history.matches(for: "goo")
        #expect(matches.strong.map(\.title) == ["Google"])
        #expect(matches.weak.isEmpty)
    }

    @Test("las búsquedas que ya estaban guardadas de antes tampoco se proponen")
    func storedSearchResultPagesAreIgnored() throws {
        let stored = """
        {"capacity":5000,"entries":[{"url":"https://www.google.com/search?q=hacker+news","title":"hacker news","visits":4,"lastVisit":0}]}
        """
        let history = try JSONDecoder().decode(History.self, from: Data(stored.utf8))
        #expect(history.entries.count == 1)
        #expect(history.matches(for: "goo").strong.isEmpty)
        #expect(history.matches(for: "hacker").weak.isEmpty)
    }

    @Test("una búsqueda no se guarda en el historial")
    func searchResultPagesAreNotRecorded() {
        var history = History()
        history.record(url: URL(string: "https://www.google.com/search?q=paella")!, title: "paella", at: Date(), newVisit: true)
        #expect(history.entries.isEmpty)
    }

    @Test("al escribir el principio de un sitio gana su portada, aunque una página interior tenga más visitas")
    func siteRootBeatsDeeperPages() {
        let history = history([
            ("https://github.com/vigosan/nada/issues", "Issues", 9),
            ("https://github.com/", "GitHub", 1),
        ])
        #expect(history.matches(for: "git").strong.map(\.title) == ["GitHub", "Issues"])
    }

    @Test("entre coincidencias iguales gana la página más visitada")
    func moreVisitsRankHigher() {
        let history = history([
            ("https://github.com/a", "A", 1),
            ("https://github.com/b", "B", 4),
        ])
        #expect(history.matches(for: "git").strong.map(\.title) == ["B", "A"])
    }

    @Test("se encuentra una página por su título sin tildes ni mayúsculas")
    func titleMatchingIgnoresCaseAndAccents() {
        let history = history([("https://example.com/receta", "Receta de paella valenciana", 1)])
        #expect(history.matches(for: "PAELLA").weak.count == 1)
        #expect(history.matches(for: "tortilla").weak.isEmpty)
    }

    @Test("el historial no crece sin fin: al llenarse olvida lo más antiguo")
    func oldestEntriesAreForgotten() {
        var history = History(capacity: 2)
        for index in 0..<3 {
            history.record(url: URL(string: "https://example.com/\(index)")!, title: "\(index)", at: Date(timeIntervalSince1970: Double(index)), newVisit: true)
        }
        #expect(history.entries.map(\.title).sorted() == ["1", "2"])
    }

    @Test("borrar el historial no deja rastro")
    func clearingForgetsEverything() {
        var history = history([("https://example.com/", "Example", 3)])
        history.clear()
        #expect(history.entries.isEmpty)
    }

    @Test("en la paleta, el sitio que empieza por lo escrito va antes que nada y lo demás del historial va tras las órdenes")
    func paletteOrdersHistoryAroundCommands() {
        let history = history([
            ("https://recargas.example/", "Recargas", 2),
            ("https://example.com/guia", "Cómo recargar la tarjeta", 5),
        ])
        let items = Palette.items(query: "recar", tabTitles: [], history: history)
        #expect(items.map(\.action) == [
            .open(URL(string: "https://recargas.example/")!),
            .reload,
            .open(URL(string: "https://example.com/guia")!),
            .open(AddressResolver.url(for: "recar")!),
        ])
        #expect(items[0].title == "Recargas")
        #expect(items[0].shortcut == "recargas.example")
    }

    @Test("borrar el historial se puede lanzar desde la paleta")
    func clearIsReachableFromThePalette() {
        #expect(Palette.items(query: "borrar historial", tabTitles: []).first?.action == .clearHistory)
    }
}
