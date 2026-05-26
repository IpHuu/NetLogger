// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NetLogger",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "NetLogger", targets: ["NetLogger"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NetLogger",
            dependencies: [],
            path: "Sources"
        ),
    ]
)
