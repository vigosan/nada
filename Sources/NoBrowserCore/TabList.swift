public struct TabList<Tab> {
    public private(set) var tabs: [Tab] = []
    public private(set) var activeIndex: Int?

    public init() {}

    public var active: Tab? {
        activeIndex.map { tabs[$0] }
    }

    public mutating func append(_ tab: Tab) {
        tabs.append(tab)
        activeIndex = tabs.count - 1
    }

    public mutating func select(_ index: Int) {
        guard tabs.indices.contains(index) else { return }
        activeIndex = index
    }

    public mutating func closeActive() -> Tab? {
        guard let index = activeIndex else { return nil }
        let closed = tabs.remove(at: index)
        activeIndex = tabs.isEmpty ? nil : min(index, tabs.count - 1)
        return closed
    }
}
