// swift-tools-version:3.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SmartLock",
    targets: [
        Target(
            name: "lockd",
            dependencies: [.Target(name: "CoreLock")]
        ),
        Target(
            name: "CoreLock"
        )
    ],
    dependencies: [
        .Package(url: "https://github.com/PureSwift/GATT", majorVersion: 2),
        .Package(url: "https://github.com/krzyzanowskim/CryptoSwift", majorVersion: 0),
    ],
    exclude: ["Xcode", "iOS", "Android"]
)
