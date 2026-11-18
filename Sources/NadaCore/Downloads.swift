public enum DownloadState: Equatable, Sendable {
    case running(Double)
    case finished
    case failed
    case cancelled
}

public struct Download: Equatable, Sendable {
    public let id: Int
    public let name: String
    public var state: DownloadState

    var fraction: Double? {
        if case .running(let fraction) = state { return fraction }
        return nil
    }
}

public struct DownloadList {
    public private(set) var items: [Download] = []
    private var nextID = 0

    public init() {}

    public var running: Int {
        items.compactMap(\.fraction).count
    }

    public var progress: Double? {
        let fractions = items.compactMap(\.fraction)
        return fractions.isEmpty ? nil : fractions.reduce(0, +) / Double(fractions.count)
    }

    public mutating func start(name: String) -> Int {
        nextID += 1
        items.insert(Download(id: nextID, name: name, state: .running(0)), at: 0)
        return nextID
    }

    public mutating func update(_ id: Int, to state: DownloadState) {
        guard let index = items.firstIndex(where: { $0.id == id }), items[index].fraction != nil else { return }
        items[index].state = state
    }
}
