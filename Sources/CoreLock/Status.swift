//
//  Status.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 4/16/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import TLVCoding

/// Lock status
public enum LockStatus: UInt8, CaseIterable, Sendable {
    
    /// Initial Status
    case setup = 0x00
    
    /// Idle / Unlock Mode
    case unlock = 0x01
}

internal extension LockStatus {
    
    init?(stringValue: String) {
        guard let value = Swift.type(of: self).allCases.first(where: { $0.stringValue == stringValue })
            else { return nil }
        self = value
    }
    
    var stringValue: String {
        switch self {
        case .setup: return "setup"
        case .unlock: return "unlock"
        }
    }
}

// MARK: - CustomStringConvertible

extension LockStatus: CustomStringConvertible {
    
    public var description: String {
        return stringValue
    }
}

// MARK: - Codable

extension LockStatus: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let value = LockStatus(stringValue: rawValue) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid string value \(rawValue)")
        }
        self = value
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}

// MARK: - TLVCodable

extension LockStatus: TLVCodable {
    
    public init?(tlvData: Data) {
        guard tlvData.count == 1
            else { return nil }
        self.init(rawValue: tlvData[0])
    }
    
    public var tlvData: Data {
        return Data([rawValue])
    }
}
