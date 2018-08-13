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
        .Package(url: "https://github.com/PureSwift/GATT", majorVersion: 2)
    ],
    exclude: ["Xcode", "iOS", "Android"]
)

#if os(macOS)
package.dependencies.append(.Package(url: "https://github.com/PureSwift/BluetoothDarwin.git", majorVersion: 1))
#elseif os(Linux)
package.dependencies.append(.Package(url: "https://github.com/PureSwift/BluetoothLinux.git", majorVersion: 3))
#endif

#if swift(>=3.2)
package.dependencies.append(.Package(url: "https://github.com/krzyzanowskim/CryptoSwift", majorVersion: 0, minor: 7))
#elseif swift(>=3.0)
package.dependencies.append(.Package(url: "https://github.com/krzyzanowskim/CryptoSwift", majorVersion: 0, minor: 6))
#endif

#if swift(>=3.2)
#elseif swift(>=3.0)
package.dependencies.append(.Package(url: "https://github.com/PureSwift/Codable.git", majorVersion: 1))
#endif
