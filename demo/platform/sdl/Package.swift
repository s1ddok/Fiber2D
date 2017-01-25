import PackageDescription

var dependencies: [Package.Dependency] = [
    .Package(url: "https://github.com/s1ddok/CSDL2", Version(1, 0, 0)),
    .Package(url: "../../../", Version(0, 0, 1))
]

#if os(Android)
dependencies += [
    .Package(url: "https://github.com/s1ddok/CAndroidAppGlue", majorVersion: 1),
]
#endif

#if os(Android)
let exclude: [String] = ["Sources/main.swift"]
#else
let exclude: [String] = []
#endif

#if os(Android)
let name = "f2dc"
#else
let name = "Fiber2D-demo"
#endif

let package = Package(
    name: name,
    dependencies: dependencies,
    exclude: exclude
)
