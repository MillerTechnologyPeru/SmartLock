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
    
    static let raspberryPi3: LockModel = "RaspberryPi3"
}

// MARK: - Darwin

#if os(macOS)
    
    public extension LockModel {
        
        static var mac: LockModel {
            
            return LockModel(rawValue: UIDevice.current.model)
        }
    }
    
#endif

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
