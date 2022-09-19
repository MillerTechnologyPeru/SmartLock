//
//  Task.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/19/22.
//

internal extension Task where Success == Never, Failure == Never {
    
    static func sleep(timeInterval: Double) async throws {
        try await sleep(nanoseconds: UInt64(timeInterval * Double(1_000_000_000)))
    }
}
