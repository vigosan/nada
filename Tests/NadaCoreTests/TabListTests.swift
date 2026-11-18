import Testing
@testable import NadaCore

@Suite("Las pestañas nunca dejan a la persona mirando una página que no eligió")
struct TabListTests {
    @Test("una pestaña nueva pasa a ser la activa porque se abre para usarla ya")
    func appendingActivates() {
        var list = TabList<String>()
        list.append("a")
        list.append("b")
        #expect(list.active == "b")
        #expect(list.activeIndex == 1)
    }

    @Test("una pestaña abierta en segundo plano queda junto a la actual y no quita de delante lo que se estaba leyendo")
    func insertingInBackgroundKeepsTheActiveTab() {
        var list = TabList<String>()
        ["a", "b", "c"].forEach { list.append($0) }
        list.select(0)
        list.insertAfterActive("x")
        #expect(list.tabs == ["a", "x", "b", "c"])
        #expect(list.active == "a")
    }

    @Test("al cerrar una pestaña intermedia se activa la que ocupa su hueco")
    func closingMiddleActivatesNeighbour() {
        var list = TabList<String>()
        ["a", "b", "c"].forEach { list.append($0) }
        list.select(1)
        #expect(list.closeActive() == "b")
        #expect(list.tabs == ["a", "c"])
        #expect(list.active == "c")
    }

    @Test("al cerrar la última se activa la anterior")
    func closingLastActivatesPrevious() {
        var list = TabList<String>()
        ["a", "b"].forEach { list.append($0) }
        #expect(list.closeActive() == "b")
        #expect(list.active == "a")
    }

    @Test("al cerrar la única pestaña no queda ninguna activa")
    func closingOnlyTabLeavesNothing() {
        var list = TabList<String>()
        list.append("a")
        #expect(list.closeActive() == "a")
        #expect(list.active == nil)
        #expect(list.closeActive() == nil)
    }

    @Test("pestaña siguiente y anterior dan la vuelta para recorrerlas todas con una sola tecla")
    func nextAndPreviousWrapAround() {
        var list = TabList<String>()
        ["a", "b", "c"].forEach { list.append($0) }
        list.selectNext()
        #expect(list.active == "a")
        list.selectPrevious()
        #expect(list.active == "c")
        list.selectPrevious()
        #expect(list.active == "b")
    }

    @Test("un atajo a una pestaña que no existe no cambia nada")
    func selectingOutOfRangeIsIgnored() {
        var list = TabList<String>()
        list.append("a")
        list.select(7)
        #expect(list.activeIndex == 0)
    }
}
