// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Nada",
    platforms: [.macOS("15.4")],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .target(name: "NadaCore"),
        .executableTarget(
            name: "Nada",
            dependencies: ["NadaCore", .product(name: "Sparkle", package: "Sparkle")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(name: "NadaCoreTests", dependencies: ["NadaCore"]),
    ]
)
