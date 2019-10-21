//
//  EventsResponse.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 10/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public struct EventsResponse: Equatable {
    
    public let encryptedData: LockNetService.EncryptedData
}

// MARK: - Codable

extension EventsResponse: Codable {
    
    public init(from decoder: Decoder) throws {
        self.encryptedData = try LockNetService.EncryptedData(from: decoder)
    }
    
    public func encode(to encoder: Encoder) throws {
        try encryptedData.encode(to: encoder)
    }
}

// MARK: - Encryption

public extension EventsResponse {
    
    init(encrypt value: EventsList,
         with key: KeyData,
         encoder: JSONEncoder = JSONEncoder()) throws {
        
        let data = try encoder.encode(value)
        self.encryptedData = try .init(encrypt: data, with: key)
    }
    
    func decrypt(with key: KeyData,
                 decoder: JSONDecoder = JSONDecoder()) throws -> EventsList {
        
        let data = try encryptedData.decrypt(with: key)
        return try decoder.decode(EventsList.self, from: data)
    }
}
