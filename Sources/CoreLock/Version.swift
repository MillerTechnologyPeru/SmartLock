//
//  Version.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

public struct SmartLockVersion {
    
    public var major: UInt8
    
    public var minor: UInt8
    
    public var patch: UInt8
}

// MARK: - Current version

public extension SmartLockVersion {
    
    public static let current = SmartLockVersion(major: 0, minor: 0, patch: 1)
}

// MARK: - Equatable

extension SmartLockVersion: Equatable {
    
    public static func == (lhs: SmartLockVersion, rhs: SmartLockVersion) -> Bool {
        
        return lhs.major == rhs.major
            && lhs.minor == rhs.minor
            && lhs.patch == rhs.patch
    }
}
