// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Fiber2D",
    products: [
        .library(name: "Fiber2D", type: .static, targets: ["Fiber2D"]),
        .executable(name: "Fiber2D-macOS", targets: ["Fiber2D-macOSDemo"])
    ],
    dependencies: [
        .package(url: "https://github.com/s1ddok/CChipmunk2D", .upToNextMinor(from: "2.0.0")),
        .package(url: "https://github.com/s1ddok/Cpng", .upToNextMinor(from: "2.0.0")),
        .package(url: "external/SwiftBGFX", .upToNextMinor(from: "2.0.0")),
        // Add this for Linux/Android or macOS (not recommended):
        // https://github.com/s1ddok/CSDL2 1.0.0
    ],
    targets: [
        .target(
            name: "Fiber2D",
            dependencies: [
                "Cpng",
                "CChipmunk2D",
                "SwiftBGFX"
            ],
            path: ".",
            sources: ["Fiber2D"]
            ),
        .target(
            name: "Fiber2D-macOSDemo",
            dependencies: ["Fiber2D"],
            path: "./demo",
            sources: ["MainScene.swift",
                      "UserComponents.swift",
                      "platform/apple/Fiber2D-demo/main.swift",
                      "platform/apple/Fiber2D-demo/AppDelegate.swift",
                      "platform/apple/Fiber2D-demo/MetalView.swift"])
    ],
    swiftLanguageVersions: [4]
)

