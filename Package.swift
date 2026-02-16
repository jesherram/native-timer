// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Jesushr0013NativeTimer",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "Jesushr0013NativeTimer",
            targets: ["Jesushr0013NativeTimer"])
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
            sources: ["Plugin", "LiveActivitiesKit"],
            linkerSettings: [
                .unsafeFlags(["-weak_framework", "SwiftUICore"])
            ])
    ]
)
