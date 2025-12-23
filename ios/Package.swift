// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MeycagesalNativeTimer",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "MeycagesalNativeTimer",
            targets: ["MeycagesalNativeTimer"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "MeycagesalNativeTimer",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: ".",
            sources: ["Plugin", "LiveActivitiesKit"])
    ]
)
