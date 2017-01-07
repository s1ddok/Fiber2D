import PackageDescription

let package = Package(
    name: "Fiber2D",
    dependencies: [
        .Package(url: "https://github.com/s1ddok/CChipmunk2D", Version(1, 0, 0)),
        .Package(url: "https://github.com/s1ddok/Cpng", Version(1, 0, 0)),
        .Package(url: "https://github.com/SwiftGFX/SwiftBGFX", Version(1, 0, 0))
    ],
    exclude: ["demo", "external", "shaders", "misc"]
)

let ar = Product(name: "Fiber2D", type: .Library(.Dynamic), modules: ["Fiber2D"])
products.append(ar)
