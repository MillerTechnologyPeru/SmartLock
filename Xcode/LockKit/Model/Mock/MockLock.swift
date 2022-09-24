//
//  MockLock.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/24/22.
//

import Foundation
import CoreLock

#if DEBUG
public struct MockLock: Equatable, Hashable, Codable, Identifiable {
    
    public let id: UUID
    
    public var status: LockStatus
    
    public var sharedSecret: KeyData
    
    public var keys: [Key] = []
}

internal extension Store {
    
    func insertMockData() {
        let maxLocks = 3
        for index in 0 ..< maxLocks  {
            let lock = MockLock.locks[index]
            let key = self.applicationData.locks[lock.id]?.key ?? Key(
                id: UUID(),
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
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(uuidString: "CCAB00A4-A0BE-4D43-B0D6-A9BAB4628256")!,
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(uuidString: "2AF2BFF2-F826-4154-AA61-E2D41C45CF34")!,
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
        MockLock(
            id: UUID(),
            status: .unlock,
            sharedSecret: KeyData()
        ),
    ]
}
#endif
