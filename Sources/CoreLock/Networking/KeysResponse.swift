//
//  KeysResponse.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 10/16/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
/*
public struct KeysResponse: Equatable {
    
    public let encryptedData: Data
}

// MARK: - Codable

extension KeysResponse: Codable {
    
    public init(from decoder: Decoder) throws {
        self.encryptedData = try Data(from: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        try encryptedData.encode(to: encoder)
    }
}

// MARK: - Encryption

public extension KeysResponse {
    
    init(encrypt value: KeysList,
         with key: KeyData,
         encoder: JSONEncoder = JSONEncoder()) throws {
        
        let data = try encoder.encode(value)
        self.encryptedData = try .init(encrypt: data, with: key)
    }
    
     func decrypt(using key: KeyData,
                  decoder: JSONDecoder = JSONDecoder()) throws -> KeysList {
        
        let data = try encryptedData.decrypt(using: key)
        return try decoder.decode(KeysList.self, from: data)
    }
}
*/
