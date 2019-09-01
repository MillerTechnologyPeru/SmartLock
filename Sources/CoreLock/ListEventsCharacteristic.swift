//
//  ListEventsCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/31/19.
//

import Foundation
import Bluetooth

/// List events request
public struct ListEventsCharacteristic: TLVCharacteristic, Codable, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "98433693-D5BB-44A4-A929-63B453C3A8C4")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    /// Identifier of key making request.
    public let identifier: UUID
    
    /// HMAC of key and nonce, and HMAC message
    public let authentication: Authentication
    
    /// Fetch limit for events to view.
    public let fetchRequest: FetchRequest?
    
    public init(identifier: UUID,
                authentication: Authentication,
                fetchRequest: FetchRequest? = nil) {
        
        self.identifier = identifier
        self.authentication = authentication
        self.fetchRequest = fetchRequest
    }
}

public extension ListEventsCharacteristic {
    
    struct FetchRequest: Codable, Equatable {
        
        /// The fetch offset of the fetch request.
        public var offset: UInt8
        
        /// The fetch limit of the fetch request.
        public var limit: UInt8?
        
        /// The predicate of the fetch request.
        public var predicate: Predicate?
        
        public init(offset: UInt8 = 0,
                    limit: UInt8? = nil,
                    predicate: Predicate? = nil) {
            
            self.offset = offset
            self.limit = limit
            self.predicate = predicate
        }
    }
    
    struct Predicate: Codable, Equatable {
        
        public var keys: [UUID]?
        
        public var start: Date?
        
        public var end: Date?
        
        public static var empty: Predicate { return .init(keys: nil, start: nil, end: nil) }
        
        public init(keys: [UUID]?,
                    start: Date? = nil,
                    end: Date? = nil) {
            
            self.keys = keys
            self.start = start
            self.end = end
        }
    }
}

public extension Collection where Self.Element == LockEvent {
    
    func fetch(_ fetchRequest: ListEventsCharacteristic.FetchRequest) -> [LockEvent] {
        
        guard isEmpty == false else { return [] }
        let limit = Int(fetchRequest.limit ?? .max)
        let offset = Int(fetchRequest.offset)
        let predicate = fetchRequest.predicate ?? .empty
        return sorted(by: { $0.date > $1.date })
            .lazy
            .suffix(from: offset)
            .lazy
            .prefix(limit)
            .filter(predicate)
    }
    
    func filter(_ predicate: ListEventsCharacteristic.Predicate) -> [LockEvent] {
        
        // don't filter
        guard predicate != .empty else { return Array(self) }
        var value = Array(self)
        // filter by keys
        if let keys = predicate.keys,
            keys.isEmpty == false {
            value.removeAll(where: { keys.contains($0.key) == false })
        }
        // filter by date
        if let startDate = predicate.start {
            value.removeAll(where: { $0.date < startDate })
        }
        if let endDate = predicate.end {
            value.removeAll(where: { $0.date > endDate })
        }
        return value
    }
}
