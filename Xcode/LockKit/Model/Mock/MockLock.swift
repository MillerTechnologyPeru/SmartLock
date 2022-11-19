//
//  MockLock.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/24/22.
//

import Foundation
import CoreLock

#if DEBUG
public struct MockLock: Equatable, Codable, Identifiable {
    
    public var id: UUID = UUID()
    
    public var status: LockStatus = .unlock
    
    public var sharedSecret: KeyData = KeyData()
    
    public var events: [LockEvent] = []
    
    public var keys: [Key] = []
    
    public var newKeys: [NewKey] = []
}

internal extension Store {
    
    func insertMockData() {
        let maxLocks = 3
        for index in 0 ..< maxLocks  {
            let lock = MockLock.locks[index]
            let key = lock.keys.first ?? Key(
                id: UUID(uuidString: "53F21D45-2E82-43CC-9FDC-18313511\(UInt16(index).toHexadecimal())")!,
                name: "Owner",
                created: Date() - TimeInterval(60 * (maxLocks - index + 1)),
                permission: .owner
            )
            // add lock and key to file
            self.applicationData.locks[lock.id] = .init(
                key: key,
                name: "My lock \(index + 1)",
                information: .init(
                    buildVersion: .current,
                    version: .current,
                    status: .unlock,
                    unlockActions: [.default]
                )
            )
            // insert key data into keychain
            if self[key: key.id] == nil {
                self[key: key.id] = KeyData()
            }
        }
    }
}

public extension MockLock {
    
    static var locks: [MockLock] = [
        MockLock(
            id: UUID(uuidString: "669A06D7-5AE5-431B-971C-7A118E77CA51")!,
            events: [
                .setup(
                    .init(
                        id: UUID(uuidString: "3CEAD223-2CBF-4216-85CD-CAD79302E235")!,
                        date: Date() - TimeInterval(60 * (3 - 0 + 1)),
                        key: UUID(uuidString: "53F21D45-2E82-43CC-9FDC-18313511\(UInt16(0x00).toHexadecimal())")!
                    )
                ),
                .unlock(
                    .init(
                        id: UUID(uuidString: "5DC5E7CF-2C34-4876-8BE8-853CAF64BE84")!,
                        date: Date() - 10,
                        key: UUID(uuidString: "53F21D45-2E82-43CC-9FDC-18313511\(UInt16(0x00).toHexadecimal())")!,
                        action: .default
                    )
                )
            ],
            keys: [
                Key(
                    id: UUID(uuidString: "53F21D45-2E82-43CC-9FDC-18313511\(UInt16(0x00).toHexadecimal())")!,
                    name: "Owner",
                    created: Date() - TimeInterval(60 * (3 - 0 + 1)),
                    permission: .owner
                )
            ]
        ),
        MockLock(
            id: UUID(uuidString: "CCAB00A4-A0BE-4D43-B0D6-A9BAB4628256")!,
            status: .unlock,
            sharedSecret: KeyData(),
            events: [
                .setup(
                    .init(
                        id: UUID(uuidString: "3CEAD223-2CBF-4216-85CD-CAD79302E201")!,
                        date: Date() - TimeInterval(60 * (3 - 1 + 1)),
                        key: UUID(uuidString: "53F21D45-2E82-43CC-9FDC-18313511\(UInt16(0x01).toHexadecimal())")!
                    )
                ),
                .unlock(
                    .init(
                        id: UUID(uuidString: "5DC5E7CF-2C34-4876-8BE8-853CAF64BE02")!,
                        date: Date() - 10,
                        key: UUID(uuidString: "53F21D45-2E82-43CC-9FDC-18313511\(UInt16(0x01).toHexadecimal())")!,
                        action: .default
                    )
                )
            ],
            keys: [
                Key(
                    id: UUID(uuidString: "53F21D45-2E82-43CC-9FDC-18313511\(UInt16(0x01).toHexadecimal())")!,
                    name: "Owner",
                    created: Date() - TimeInterval(60 * (3 - 1 + 1)),
                    permission: .owner
                )
            ]
        ),
        MockLock(
            id: UUID(uuidString: "2AF2BFF2-F826-4154-AA61-E2D41C45CF34")!,
            status: .unlock,
            sharedSecret: KeyData(),
            events: [
                .setup(
                    .init(
                        id: UUID(uuidString: "3CEAD223-2CBF-4216-85CD-CAD79302E202")!,
                        date: Date() - TimeInterval(60 * (3 - 2 + 1)),
                        key: UUID(uuidString: "53F21D45-2E82-43CC-9FDC-18313511\(UInt16(0x02).toHexadecimal())")!
                    )
                ),
                .unlock(
                    .init(
                        id: UUID(uuidString: "5DC5E7CF-2C34-4876-8BE8-853CAF64BE02")!,
                        date: Date() - 10,
                        key: UUID(uuidString: "53F21D45-2E82-43CC-9FDC-18313511\(UInt16(0x02).toHexadecimal())")!,
                        action: .default
                    )
                )
            ],
            keys: [
                Key(
                    id: UUID(uuidString: "53F21D45-2E82-43CC-9FDC-18313511\(UInt16(0x02).toHexadecimal())")!,
                    name: "Owner",
                    created: Date() - TimeInterval(60 * (3 - 2 + 1)),
                    permission: .owner
                )
            ]
        ),
        MockLock(),
        MockLock(),
        MockLock(),
        MockLock(),
        MockLock(),
        MockLock(),
        MockLock(),
        MockLock(),
        MockLock(),
        MockLock(),
        MockLock(),
        MockLock()
    ]
}
#endif
