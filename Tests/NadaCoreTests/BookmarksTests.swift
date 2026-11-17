import Foundation
import Testing
@testable import NadaCore

@Suite("Los marcadores guardan lo que quieres volver a encontrar, ordenado a tu manera")
struct BookmarksTests {
    private let github = URL(string: "https://github.com/")!
    private let docs = URL(string: "https://developer.apple.com/documentation")!
    private let recipe = URL(string: "https://example.com/paella")!

    private func sample() -> Bookmarks {
        var bookmarks = Bookmarks()
        bookmarks.save(url: github, title: "GitHub", category: "Trabajo")
        bookmarks.save(url: docs, title: "Apple Developer Documentation", category: "Trabajo")
        bookmarks.save(url: recipe, title: "Paella valenciana", category: "Cocina")
        return bookmarks
    }

    @Test("guardar otra vez una página la mueve de categoría en lugar de duplicarla")
    func savingAgainMovesTheBookmark() {
        var bookmarks = sample()
        bookmarks.save(url: github, title: "GitHub", category: "Código")
        #expect(bookmarks.items.count == 3)
        #expect(bookmarks.bookmark(for: github)?.category == "Código")
    }

    @Test("las categorías salen sin repetir y en orden alfabético, y desaparecen al quedarse vacías")
    func categoriesAreDerivedFromBookmarks() {
        var bookmarks = sample()
        #expect(bookmarks.categories == ["Cocina", "Trabajo"])
        bookmarks.remove(url: recipe)
        #expect(bookmarks.categories == ["Trabajo"])
        #expect(bookmarks.bookmark(for: recipe) == nil)
    }

    @Test("un marcador se encuentra por título, dirección o categoría, sin tildes ni mayúsculas")
    func matchingCoversTitleAddressAndCategory() {
        let bookmarks = sample()
        #expect(bookmarks.matches(for: "PAELLA").map(\.url) == [recipe])
        #expect(bookmarks.matches(for: "developer.apple").map(\.url) == [docs])
        #expect(bookmarks.matches(for: "trabajo").count == 2)
        #expect(bookmarks.matches(for: "  ").isEmpty)
    }

    @Test("al guardar se ofrecen las categorías que ya existen y una para dejarlo sin clasificar")
    func savingOffersExistingCategories() {
        let items = Palette.bookmarkSaveItems(query: "", bookmarks: sample(), page: recipe.appending(path: "otra"))
        #expect(items.map(\.action) == [
            .saveBookmark(category: Bookmarks.uncategorized),
            .saveBookmark(category: "Cocina"),
            .saveBookmark(category: "Trabajo"),
        ])
    }

    @Test("escribir un nombre nuevo crea la categoría, y uno que ya existe no la duplica")
    func typingCreatesACategory() {
        let page = recipe.appending(path: "otra")
        let new = Palette.bookmarkSaveItems(query: "Viajes", bookmarks: sample(), page: page)
        #expect(new.map(\.action) == [.saveBookmark(category: "Viajes")])
        #expect(new.first?.title == "Crear categoría «Viajes»")
        let existing = Palette.bookmarkSaveItems(query: "cocina", bookmarks: sample(), page: page)
        #expect(existing.map(\.action) == [.saveBookmark(category: "Cocina")])
    }

    @Test("una página ya guardada ofrece primero quitarla, y dice en qué categoría está")
    func savedPageOffersRemoval() {
        let items = Palette.bookmarkSaveItems(query: "", bookmarks: sample(), page: github)
        #expect(items.first?.action == .removeBookmark)
        #expect(items.first?.shortcut == "Trabajo")
    }

    @Test("los marcadores se exploran por categorías con su número de páginas, y dentro de cada una se abren")
    func browsingGoesThroughCategories() {
        let root = Palette.bookmarkItems(query: "", bookmarks: sample(), category: nil)
        #expect(root.map(\.action) == [.openBookmarkCategory("Cocina"), .openBookmarkCategory("Trabajo")])
        #expect(root.map(\.shortcut) == ["1 ›", "2 ›"])
        let work = Palette.bookmarkItems(query: "", bookmarks: sample(), category: "Trabajo")
        #expect(work.map(\.action) == [.open(github), .open(docs)])
        #expect(work.first?.shortcut == "github.com")
    }

    @Test("buscar en la raíz de marcadores encuentra páginas de cualquier categoría")
    func browsingSearchCrossesCategories() {
        let found = Palette.bookmarkItems(query: "paella", bookmarks: sample(), category: nil)
        #expect(found.map(\.action) == [.open(recipe)])
    }

    @Test("en la paleta un marcador sale con su estrella y su categoría, antes que las órdenes")
    func paletteSuggestsBookmarks() {
        let items = Palette.items(query: "git", tabTitles: [], bookmarks: sample())
        #expect(items.first?.action == .open(github))
        #expect(items.first?.shortcut == "★ Trabajo")
    }

    @Test("una página que está en marcadores y en el historial no sale dos veces")
    func bookmarkedHistoryIsNotRepeated() {
        var history = History()
        history.record(url: github, title: "GitHub", at: Date(timeIntervalSince1970: 1), newVisit: true)
        let items = Palette.items(query: "git", tabTitles: [], history: history, bookmarks: sample())
        #expect(items.filter { $0.action == .open(github) }.count == 1)
        #expect(items.first?.shortcut == "★ Trabajo")
    }

    @Test("guardar y abrir marcadores tienen atajo y se alcanzan desde la paleta")
    func bookmarkCommands() {
        let bindings = KeyBindings(config: "")
        #expect(bindings.action(for: KeyCombo("cmd+b")!) == .bookmarkPage)
        #expect(bindings.action(for: KeyCombo("cmd+opt+b")!) == .openBookmarks)
        #expect(Palette.items(query: "guardar en marcadores", tabTitles: []).first?.action == .bookmarkPage)
        #expect(Palette.items(query: "marcadores", tabTitles: []).first?.action == .openBookmarks)
    }
}
