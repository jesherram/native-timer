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
            name: "NativeTimerLiveActivities",
            targets: ["NativeTimerLiveActivities"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "NativeTimerCore",
            dependencies: [],
            path: "ios/Core"),
        .target(
            name: "Jesushr0013NativeTimer",
            dependencies: [
                "NativeTimerCore",
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Plugin"),
        .target(
            name: "NativeTimerLiveActivities",
            dependencies: [
                "NativeTimerCore"
            ],
            path: "ios/LiveActivities")
    ]
)
