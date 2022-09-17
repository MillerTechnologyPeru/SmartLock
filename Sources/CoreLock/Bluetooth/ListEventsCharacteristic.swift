//
//  ListEventsCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/31/19.
//

import Foundation
import Bluetooth
import GATT

/// List events request
public struct ListEventsCharacteristic: TLVEncryptedCharacteristic, Codable, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "98433693-D5BB-44A4-A929-63B453C3A8C4")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    public let encryptedData: EncryptedData
    
    public init(encryptedData: EncryptedData) {
        self.encryptedData = encryptedData
    }
    
    public init(request: ListEventsRequest, using key: KeyData, id: UUID) throws {
        
        let requestData = try type(of: self).encoder.encode(request)
        self.encryptedData = try EncryptedData(encrypt: requestData, using: key, id: id)
    }
    
    public func decrypt(with key: KeyData) throws -> ListEventsRequest {
        
        let data = try encryptedData.decrypt(using: key)
        guard let value = try? type(of: self).decoder.decode(ListEventsRequest.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
}

public struct ListEventsRequest: Codable, Equatable {
    
    /// Fetch limit for events to view.
    public let fetchRequest: LockEvent.FetchRequest?
    
    public init(fetchRequest: LockEvent.FetchRequest? = nil) {
        self.fetchRequest = fetchRequest
    }
}

// MARK: - Central

public extension GATTConnection {
    
    /// Retreive a list of events on device.
    func listEvents(
        fetchRequest: LockEvent.FetchRequest? = nil,
        using key: KeyCredentials,
        log: ((String) -> ())? = nil
    ) async throws -> AsyncThrowingStream<EventListNotification, Error> {
        let write = {
            try ListEventsCharacteristic(
                request: ListEventsRequest(fetchRequest: fetchRequest),
                using: key.secret,
                id: key.id
            )
        }
        return try await list(write(), EventsCharacteristic.self, key: key, log: log)
    }
}
