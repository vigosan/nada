import Testing
@testable import NoBrowserCore

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

    @Test("un atajo a una pestaña que no existe no cambia nada")
    func selectingOutOfRangeIsIgnored() {
        var list = TabList<String>()
        list.append("a")
        list.select(7)
        #expect(list.activeIndex == 0)
    }
}
