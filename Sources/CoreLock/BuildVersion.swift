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
    
    static var current: SmartLockBuildVersion { return SmartLockBuildVersion(rawValue: GitCommits) }
}

}

// MARK: - CustomStringConvertible

extension SmartLockBuildVersion: CustomStringConvertible {
    
    public var description: String {
        
        return rawValue.description
    }
}
