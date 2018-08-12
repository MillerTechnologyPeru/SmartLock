//
//  LockHardware.swift
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

/// Lock Configuration
public struct LockHardware {
    
    /// Lock serial number
    public let serialNumber: String
    
    /// Lock Model
    public var model: LockModel
}

// MARK: - Codable

extension LockHardware: Codable {
    
    public enum CodingKeys: String, CodingKey {
        
        case serialNumber
        case model
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.serialNumber = try container.decode(String.self, forKey: .serialNumber)
        self.model = try container.decode(LockModel.self, forKey: .model)
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(serialNumber, forKey: .serialNumber)
        try container.encode(model, forKey: .model)
    }
}
