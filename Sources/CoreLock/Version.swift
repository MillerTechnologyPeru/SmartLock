//
//  Version.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

public struct SmartLockBuildNumber: RawRepresentable {
    
    public let rawValue: UInt64
    
    public init(rawValue: UInt64) {
        
        self.rawValue = rawValue
    }
}

// MARK: - Current Version

public extension SmartLockBuildNumber {
    
    public static var current: SmartLockBuildNumber { return SmartLockBuildNumber(rawValue: GitCommits) }
}

// MARK: - Equatable

extension SmartLockBuildNumber: Equatable {
    
    public static func == (lhs: SmartLockBuildNumber, rhs: SmartLockBuildNumber) -> Bool {
        
        return lhs.rawValue == rhs.rawValue
    }
}

// MARK: - 
