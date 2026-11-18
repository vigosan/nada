import CoreGraphics

public enum SplitAxis: Equatable, Sendable, Codable {
    case horizontal
    case vertical
}

public enum Direction: Equatable, Sendable {
    case left
    case right
    case up
    case down

    var axis: SplitAxis {
        self == .left || self == .right ? .horizontal : .vertical
    }
}

public struct PaneLayout: Codable {
    private enum CodingKeys: CodingKey {
        case focused
        case root
        case nextID
    }

    private indirect enum Node: Codable {
        case leaf(Int)
        case split(SplitAxis, Double, Node, Node)
    }

    public private(set) var focused = 0
    public var preservesZoom = false
    private var root = Node.leaf(0)
    private var nextID = 1
    private var zoomed = false

    public init() {}

    public var frames: [Int: CGRect] {
        zoomed ? [focused: CGRect(x: 0, y: 0, width: 1, height: 1)] : allFrames
    }

    private var allFrames: [Int: CGRect] {
        var frames: [Int: CGRect] = [:]
        Self.collect(root, in: CGRect(x: 0, y: 0, width: 1, height: 1), into: &frames)
        return frames
    }

    public mutating func split(_ axis: SplitAxis) -> Int {
        let id = nextID
        nextID += 1
        root = Self.splitting(root, leaf: focused, axis: axis, new: id)
        zoomed = false
        focused = id
        return id
    }

    public mutating func closeFocused() -> Bool {
        guard case .split = root, let kept = Self.removing(focused, from: root), let next = kept.next else { return false }
        root = kept.node
        zoomed = false
        focused = next
        return true
    }

    public mutating func focus(_ id: Int) {
        guard allFrames[id] != nil, id != focused else { return }
        focused = id
        zoomed = false
    }

    public mutating func moveFocus(_ direction: Direction) {
        zoomed = zoomed && preservesZoom
        let frames = allFrames
        guard let from = frames[focused] else { return }
        let tolerance = 0.0001
        let neighbours = frames.filter { id, frame in
            guard id != focused else { return false }
            let overlapsVertically = frame.minY < from.maxY - tolerance && frame.maxY > from.minY + tolerance
            let overlapsHorizontally = frame.minX < from.maxX - tolerance && frame.maxX > from.minX + tolerance
            switch direction {
            case .left: return abs(frame.maxX - from.minX) < tolerance && overlapsVertically
            case .right: return abs(frame.minX - from.maxX) < tolerance && overlapsVertically
            case .up: return abs(frame.maxY - from.minY) < tolerance && overlapsHorizontally
            case .down: return abs(frame.minY - from.maxY) < tolerance && overlapsHorizontally
            }
        }
        let offset: (CGRect) -> Double = { frame in
            direction.axis == .horizontal ? abs(frame.minY - from.minY) : abs(frame.minX - from.minX)
        }
        let nearest = neighbours.min { (offset($0.value), $0.key) < (offset($1.value), $1.key) }
        focused = nearest?.key ?? focused
    }

    public mutating func focusNext() {
        cycle(by: 1)
    }

    public mutating func focusPrevious() {
        cycle(by: -1)
    }

    private mutating func cycle(by step: Int) {
        let order = Self.leaves(of: root)
        guard let index = order.firstIndex(of: focused) else { return }
        focused = order[(index + step + order.count) % order.count]
        zoomed = zoomed && preservesZoom
    }

    public mutating func equalize() {
        root = Self.equalized(root)
    }

    public mutating func toggleZoom() {
        zoomed.toggle()
    }

    public mutating func resize(_ direction: Direction) {
        let delta = direction == .right || direction == .down ? 0.05 : -0.05
        root = Self.resizing(root, focused: focused, axis: direction.axis, delta: delta).node
    }

    private static func collect(_ node: Node, in frame: CGRect, into frames: inout [Int: CGRect]) {
        switch node {
        case .leaf(let id):
            frames[id] = frame
        case .split(.horizontal, let ratio, let first, let second):
            let width = frame.width * ratio
            collect(first, in: CGRect(x: frame.minX, y: frame.minY, width: width, height: frame.height), into: &frames)
            collect(second, in: CGRect(x: frame.minX + width, y: frame.minY, width: frame.width - width, height: frame.height), into: &frames)
        case .split(.vertical, let ratio, let first, let second):
            let height = frame.height * ratio
            collect(first, in: CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: height), into: &frames)
            collect(second, in: CGRect(x: frame.minX, y: frame.minY + height, width: frame.width, height: frame.height - height), into: &frames)
        }
    }

    private static func splitting(_ node: Node, leaf: Int, axis: SplitAxis, new: Int) -> Node {
        switch node {
        case .leaf(let id):
            return id == leaf ? .split(axis, 0.5, node, .leaf(new)) : node
        case .split(let nodeAxis, let ratio, let first, let second):
            return .split(
                nodeAxis,
                ratio,
                splitting(first, leaf: leaf, axis: axis, new: new),
                splitting(second, leaf: leaf, axis: axis, new: new)
            )
        }
    }

    private static func removing(_ id: Int, from node: Node) -> (node: Node, next: Int?)? {
        guard case .split(let axis, let ratio, let first, let second) = node else {
            if case .leaf(id) = node { return nil }
            return (node, nil)
        }
        guard let keptFirst = removing(id, from: first) else { return (second, firstLeaf(of: second)) }
        guard let keptSecond = removing(id, from: second) else { return (first, firstLeaf(of: first)) }
        return (.split(axis, ratio, keptFirst.node, keptSecond.node), keptFirst.next ?? keptSecond.next)
    }

    private static func equalized(_ node: Node) -> Node {
        guard case .split(let axis, _, let first, let second) = node else { return node }
        let firstWeight = weight(of: first, along: axis)
        let total = firstWeight + weight(of: second, along: axis)
        return .split(axis, Double(firstWeight) / Double(total), equalized(first), equalized(second))
    }

    private static func weight(of node: Node, along axis: SplitAxis) -> Int {
        guard case .split(axis, _, let first, let second) = node else { return 1 }
        return weight(of: first, along: axis) + weight(of: second, along: axis)
    }

    private static func leaves(of node: Node) -> [Int] {
        switch node {
        case .leaf(let id): [id]
        case .split(_, _, let first, let second): leaves(of: first) + leaves(of: second)
        }
    }

    private static func firstLeaf(of node: Node) -> Int {
        switch node {
        case .leaf(let id): id
        case .split(_, _, let first, _): firstLeaf(of: first)
        }
    }

    private static func resizing(
        _ node: Node,
        focused: Int,
        axis: SplitAxis,
        delta: Double
    ) -> (node: Node, found: Bool, applied: Bool) {
        guard case .split(let nodeAxis, let ratio, let first, let second) = node else {
            if case .leaf(focused) = node { return (node, true, false) }
            return (node, false, false)
        }
        let inFirst = resizing(first, focused: focused, axis: axis, delta: delta)
        let inSecond = inFirst.found ? (node: second, found: false, applied: false) : resizing(second, focused: focused, axis: axis, delta: delta)
        let found = inFirst.found || inSecond.found
        let applied = inFirst.applied || inSecond.applied
        if found, !applied, nodeAxis == axis {
            return (.split(nodeAxis, min(0.9, max(0.1, ratio + delta)), first, second), true, true)
        }
        return (.split(nodeAxis, ratio, inFirst.node, inSecond.node), found, applied)
    }
}
