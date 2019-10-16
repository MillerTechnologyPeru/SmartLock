// swift-tools-version:5.0
import PackageDescription

#if os(Linux)
let nativeBluetooth: Target.Dependency = "BluetoothLinux"
let nativeGATT: Target.Dependency = "GATT"
#elseif os(macOS)
let nativeBluetooth: Target.Dependency = "BluetoothDarwin"
let nativeGATT: Target.Dependency = "DarwinGATT"
#endif

let package = Package(
    name: "Lock",
    products: [
        .executable(
            name: "lockd",
            targets: ["lockd"]
        ),
        .library(
            name: "CoreLock",
            targets: ["CoreLock"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/krzyzanowskim/CryptoSwift",
            .branch("master")
        ),
        .package(
            url: "https://github.com/uraimo/SwiftyGPIO.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/PureSwift/TLVCoding.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/PureSwift/BluetoothLinux.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/PureSwift/BluetoothDarwin.git",
            .branch("master")
        ),
        .package(
            url: "https://github.com/IBM-Swift/Kitura.git",
            from: "2.8.1"
        )
    ],
    targets: [
        .target(
            name: "lockd",
            dependencies: [
                nativeBluetooth,
                nativeGATT,
                "CoreLockGATTServer",
                "SwiftyGPIO",
                "CoreLockWebServer"
            ]
        ),
        .target(
            name: "CoreLock",
            dependencies: [
                nativeGATT,
                "TLVCoding",
                "CryptoSwift"
            ]
        ),
        .target(
            name: "CoreLockGATTServer",
            dependencies: ["CoreLock"]
        ),
        .target(
            name: "CoreLockWebServer",
            dependencies: [
                "CoreLock",
                "Kitura"
            ]
        ),
        .testTarget(
            name: "CoreLockTests",
            dependencies: ["CoreLock"]
        ),
        .testTarget(
            name: "CoreLockGATTServerTests",
            dependencies: ["CoreLockGATTServer"]
        )
    ]
)
