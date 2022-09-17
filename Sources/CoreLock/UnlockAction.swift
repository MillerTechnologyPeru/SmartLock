//
//  UnlockAction.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import TLVCoding
import Bluetooth

/// Unlock Action
public enum UnlockAction: UInt8, BitMaskOption {
    
    /// Unlock immediately.
    case `default` = 0b01
    
    /// Unlock when button is pressed.
    case button = 0b10
}

internal extension UnlockAction {
    
    init?(stringValue: String) {
        guard let value = type(of: self).allCases.first(where: { $0.stringValue == stringValue })
            else { return nil }
        self = value
    }
    
    var stringValue: String {
        switch self {
        case .default: return "default"
        case .button: return "button"
        }
    }
}

// MARK: - CustomStringConvertible

extension UnlockAction: CustomStringConvertible {
    
    public var description: String {
        return stringValue
    }
}

// MARK: - Codable

extension UnlockAction: Codable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        guard let value = UnlockAction(stringValue: rawValue) else {
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

extension UnlockAction: TLVCodable {
    
    public init?(tlvData: Data) {
        guard tlvData.count == 1
            else { return nil }
        self.init(rawValue: tlvData[0])
    }
    
    public var tlvData: Data {
        return Data([rawValue])
    }
}
