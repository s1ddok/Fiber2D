import PackageDescription

let package = Package(
    name: "Fiber2D",
    dependencies: [
        .Package(url: "https://github.com/SwiftGFX/SwiftMath", Version(2, 2, 0))
    ],
    exclude: ["demo", "external"]
)
