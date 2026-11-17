// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Nada",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "NadaCore"),
        .executableTarget(
            name: "Nada",
            dependencies: ["NadaCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "NadaCoreTests", dependencies: ["NadaCore"]),
    ]
)
