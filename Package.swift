// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Jesushr0013NativeTimer",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Jesushr0013NativeTimer",
            targets: ["Jesushr0013NativeTimer"]),
        .library(
            name: "Jesushr0013NativeTimerLiveActivities",
            targets: ["Jesushr0013NativeTimerLiveActivities"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "Jesushr0013NativeTimer",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios",
            sources: ["Core", "Plugin"]),
        .target(
            name: "Jesushr0013NativeTimerLiveActivities",
            dependencies: [
                "Jesushr0013NativeTimer"
            ],
            path: "ios/LiveActivities")
    ]
)
