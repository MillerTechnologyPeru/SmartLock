//
//  Version.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

public struct LockBuildVersion: RawRepresentable, Equatable, Hashable {
    
    public let rawValue: UInt64
    
    public init(rawValue: UInt64) {
        
        self.rawValue = rawValue
    }
}

// MARK: - Current Version

public extension LockBuildVersion {
    
    static var current: LockBuildVersion { return LockBuildVersion(rawValue: GitCommits) }
}

// MARK: - CustomStringConvertible

extension LockBuildVersion: CustomStringConvertible {
    
    public var description: String {
        
        return rawValue.description
    }
}
