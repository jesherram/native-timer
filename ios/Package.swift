// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NativeTimerPlugin",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "NativeTimerPlugin",
            targets: ["NativeTimerPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "NativeTimerPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "Sources")
    ]
)
