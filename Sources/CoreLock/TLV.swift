//
//  TLV.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 5/19/19.
//

import Foundation
import TLVCoding

internal extension TLVEncoder {
    
    static var lock: TLVEncoder {
        var encoder = TLVEncoder()
        encoder.numericFormat = .littleEndian
        encoder.uuidFormat = .bytes
        return encoder
    }
}

internal extension TLVDecoder {
    
    static var lock: TLVDecoder {
        var decoder = TLVDecoder()
        decoder.numericFormat = .littleEndian
        decoder.uuidFormat = .bytes
        return decoder
    }
}

// MARK: - TLVCharacteristic

public protocol TLVCharacteristic: GATTProfileCharacteristic, Codable {
    
    /// TLV Encoder used to encode values.
    static var encoder: TLVEncoder { get }
    
    /// TLV Decoder used to decode values.
    static var decoder: TLVDecoder { get }
}

public extension TLVCharacteristic {
    
    static var encoder: TLVEncoder { return .lock }
    static var decoder: TLVDecoder { return .lock }
}

public extension TLVCharacteristic where Self: Codable {
    
    init?(data: Data) {
        
        guard let value = try? Self.decoder.decode(Self.self, from: data)
            else { return nil }
        self = value
    }
    
    var data: Data {
        return try! Self.encoder.encode(self)
    }
}
