// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NetLogger",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "NetLogger", targets: ["NetLogger"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/realm-swift.git", from: "10.54.0")
    ],
    targets: [
        .target(
            name: "NetLogger",
            dependencies: [
                .product(name: "RealmSwift", package: "realm-swift")
            ],
            path: "Sources"
        ),
    ]
)
