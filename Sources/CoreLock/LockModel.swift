//
//  LockModel.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//
//

import Foundation

#if swift(>=3.2)
#elseif swift(>=3.0)
    import Codable
#endif

/// Lock Model
public struct LockModel: RawRepresentable {
    
    public let rawValue: String
    
    public init(rawValue: String) {
        
        self.rawValue = rawValue
    }
}

// MARK: - Equatable

extension LockModel: Equatable {
    
    public static func == (lhs: LockModel, rhs: LockModel) -> Bool {
        
        return lhs.rawValue == rhs.rawValue
    }
}

// MARK: - Hashable

extension LockModel: Hashable {
    
    public var hashValue: Int {
        
        return rawValue.hash
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
    
    static let orangePi: LockModel = "OrangePi"
    
    static let raspberryPi: LockModel = "RaspberryPi"
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
