//
//  Version.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

public struct SmartLockBuildVersion: RawRepresentable {
    
    public let rawValue: UInt64
    
    public init(rawValue: UInt64) {
        
        self.rawValue = rawValue
    }
}

// MARK: - Current Version

public extension SmartLockBuildVersion {
    
    public static var current: SmartLockBuildVersion { return SmartLockBuildVersion(rawValue: GitCommits) }
}

// MARK: - Equatable

extension SmartLockBuildVersion: Equatable {
    
    public static func == (lhs: SmartLockBuildVersion, rhs: SmartLockBuildVersion) -> Bool {
        
        return lhs.rawValue == rhs.rawValue
    }
}

// MARK: - CustomStringConvertible

extension SmartLockBuildVersion: CustomStringConvertible {
    
    public var description: String {
        
        return rawValue.description
    }
}
