// swift-tools-version:3.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SmartLock",
    targets: [
        Target(
            name: "lockd",
            dependencies: [.Target(name: "CoreLockGATTServer")]
        ),
        Target(
            name: "CoreLockGATTServer",
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

#if os(macOS)
let dependency: Package.Dependency = .Package(url: "https://github.com/PureSwift/BluetoothDarwin.git", majorVersion: 1)
package.dependencies.append(dependency)
#elseif os(Linux)
let dependency: Package.Dependency = .Package(url: "https://github.com/PureSwift/BluetoothLinux.git", majorVersion: 3)
package.dependencies.append(dependency)
#endif
