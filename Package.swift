import PackageDescription

var f2d_Dependencies: [Package.Dependency] = [
    .Package(url: "https://github.com/s1ddok/CChipmunk2D", Version(1, 0, 0)),
    .Package(url: "https://github.com/s1ddok/Cpng", Version(1, 0, 0)),
    .Package(url: "https://github.com/SwiftGFX/SwiftBGFX", Version(1, 0, 0))
]

// os(macOS) is excluded from this because the supported platform is Metal
// but you can add this here if you really want to use Fiber2D with SDL on macOS.
#if os(Linux) || os(Android)
f2d_Dependencies += [.Package(url: "https://github.com/s1ddok/CSDL2", Version(1, 0, 0))]
#endif

let package = Package(
    name: "Fiber2D",
    dependencies: f2d_Dependencies,
    exclude: ["demo", "external", "shaders", "misc"]
)

let ar = Product(name: "Fiber2D", type: .Library(.Dynamic), modules: ["Fiber2D"])
products.append(ar)
