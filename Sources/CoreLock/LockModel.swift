//
//  LockModel.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//
//

import Foundation

/// Lock Model
public struct LockModel: RawRepresentable, Equatable, Hashable {
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - CustomStringConvertible

extension LockModel: CustomStringConvertible {
    
    public var description: String {
        return rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension LockModel: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - Models

public extension LockModel {
    
    static let orangePiOne: LockModel = "OrangePiOne"
    static let orangePiZero: LockModel = "OrangePiZero"
    static let orangePiZero2: LockModel = "OrangePiZero2"
    static let raspberryPi3: LockModel = "RaspberryPi3"
    static let raspberryPi4: LockModel = "RaspberryPi4"
}

// MARK: - Codable

extension LockModel: Codable {
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self.init(rawValue: rawValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
