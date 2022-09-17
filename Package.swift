// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "Lock",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
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
            url: "https://github.com/PureSwift/Bluetooth.git",
            .upToNextMajor(from: "6.0.0")
        ),
        .package(
            url: "https://github.com/PureSwift/TLVCoding.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/PureSwift/BluetoothLinux.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/uraimo/SwiftyGPIO.git",
            branch: "master"
        )
    ],
    targets: [
        .executableTarget(
            name: "lockd",
            dependencies: [
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothGATT",
                    package: "Bluetooth",
                    condition: .when(platforms: [.macOS, .linux])
                ),
                .product(
                    name: "BluetoothHCI",
                    package: "Bluetooth",
                    condition: .when(platforms: [.macOS, .linux])
                ),
                .product(
                    name: "BluetoothGAP",
                    package: "Bluetooth",
                    condition: .when(platforms: [.macOS, .linux])
                ),
                .product(
                    name: "DarwinGATT",
                    package: "GATT",
                    condition: .when(platforms: [.macOS])
                ),
                .product(
                    name: "BluetoothLinux",
                    package: "BluetoothLinux",
                    condition: .when(platforms: [.linux])
                ),
                "CoreLockGATTServer",
                "SwiftyGPIO"
            ]
        ),
        .target(
            name: "CoreLock",
            dependencies: [
                "TLVCoding",
                "GATT",
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
            ]
        ),
        .target(
            name: "CoreLockGATTServer",
            dependencies: ["CoreLock"]
        ),
        .testTarget(
            name: "CoreLockTests",
            dependencies: ["CoreLock"]
        )
    ]
)

#if os(Linux)
package.dependencies.append(
    .package(
        url: "https://github.com/apple/swift-crypto.git",
        .upToNextMajor(from: "2.1.0")
    )
)
package.targets[0].dependencies.append(
    .product(
        name: "Crypto",
        package: "swift-crypto",
        condition: .when(platforms: [.linux])
    )
)
#endif
