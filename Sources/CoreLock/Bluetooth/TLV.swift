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
        encoder.numericFormatting = .littleEndian
        encoder.uuidFormatting = .bytes
        encoder.dateFormatting = .secondsSince1970
        return encoder
    }
}

internal extension TLVDecoder {
    
    static var lock: TLVDecoder {
        var decoder = TLVDecoder()
        decoder.numericFormatting = .littleEndian
        decoder.uuidFormatting = .bytes
        decoder.dateFormatting = .secondsSince1970
        return decoder
    }
}

// MARK: - TLVCharacteristic

public protocol TLVCharacteristic: GATTProfileCharacteristic {
    
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

public protocol TLVEncryptedCharacteristic: TLVCharacteristic, TLVCodable {
    
    var encryptedData: EncryptedData { get }
    
    init(encryptedData: EncryptedData)
}

public extension TLVEncryptedCharacteristic {
    
    init(from decoder: Decoder) throws {
        let encryptedData = try EncryptedData(from: decoder)
        self.init(encryptedData: encryptedData)
    }
    
    func encode(to encoder: Encoder) throws {
        try self.encryptedData.encode(to: encoder)
    }
    
    init?(tlvData: Data) {
        guard let encryptedData = EncryptedData(tlvData: tlvData) else {
            return nil
        }
        self.init(encryptedData: encryptedData)
    }
    
    var tlvData: Data {
        encryptedData.tlvData
    }
}
