import Foundation

public struct SiteZoom: Codable, Equatable {
    private var factors: [String: Double] = [:]

    public init() {}

    public func factor(for page: URL?) -> Double {
        page?.host().flatMap { factors[$0] } ?? 1
    }

    public mutating func set(_ factor: Double, for page: URL?) {
        guard let host = page?.host() else { return }
        factors[host] = abs(factor - 1) < 0.001 ? nil : factor
    }
}
