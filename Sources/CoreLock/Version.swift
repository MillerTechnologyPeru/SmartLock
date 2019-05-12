//
//  Version.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

public struct LockVersion: Equatable, Hashable {
    
    public var major: UInt8
    
    public var minor: UInt8
    
    public var patch: UInt8
}

// MARK: - Current version

public extension LockVersion {
    
    static let current = LockVersion(major: 0, minor: 0, patch: 1)
}

// MARK: - CustomStringConvertible

extension LockVersion: CustomStringConvertible {
    
    public var description: String {
        
        return "\(major).\(minor).\(patch)"
    }
}
