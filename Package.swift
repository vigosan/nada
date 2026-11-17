// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NoBrowser",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "NoBrowserCore"),
        .executableTarget(
            name: "NoBrowser",
            dependencies: ["NoBrowserCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "NoBrowserCoreTests", dependencies: ["NoBrowserCore"]),
    ]
)
