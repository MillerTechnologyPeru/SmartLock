//
//  Version.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import TLVCoding

public struct LockVersion: Equatable, Hashable, Codable {
    
    public var major: UInt8
    
    public var minor: UInt8
    
    public var patch: UInt8
}

// MARK: - Definitions

public extension LockVersion {
    
    static var current: LockVersion { return LockVersion(major: 0, minor: 0, patch: 1) }
}

// MARK: - CustomStringConvertible

extension LockVersion: CustomStringConvertible {
    
    public var description: String {
        
        return "\(major).\(minor).\(patch)"
    }
}

// MARK: - TLVCodable

extension LockVersion: TLVCodable {
    
    internal static var length: Int { return 3 }
    
    public init?(tlvData: Data) {
        guard tlvData.count == LockVersion.length
             else { return nil }
        
        self.major = tlvData[0]
        self.minor = tlvData[1]
        self.patch = tlvData[2]
    }
    
    public var tlvData: Data {
        return Data([major, minor, patch])
    }
}
