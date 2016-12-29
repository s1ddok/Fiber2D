import PackageDescription

let package = Package(
    name: "f2dc",
    dependencies: [
        .Package(url: "https://github.com/s1ddok/CSDL2", majorVersion: 1),
        .Package(url: "https://github.com/s1ddok/CAndroidAppGlue", majorVersion: 1)
    ]
)

let ar = Product(name: "f2dc", type: .Library(.Dynamic), modules: "f2dc")
products.append(ar)
