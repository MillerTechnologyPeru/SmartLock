//
//  EventStore.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 10/16/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public protocol LockEventStore: class {
    
    func fetch(_ fetchRequest: LockEvent.FetchRequest) throws -> [LockEvent]
    
    func save(_ event: LockEvent) throws
}

// MARK: - Supporting Types

public final class InMemoryLockEvents: LockEventStore {
    
    public init() { }
    
    public private(set) var events = [LockEvent]()
    
    public func fetch(_ fetchRequest: LockEvent.FetchRequest) throws -> [LockEvent] {
        return events.fetch(fetchRequest)
    }
    
    public func save(_ event: LockEvent) throws {
        events.append(event)
    }
}

// MARK: - Fetch Request

public extension LockEvent {
    
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
    
    func fetch(_ fetchRequest: LockEvent.FetchRequest) -> [LockEvent] {
        
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
    
    func filter(_ predicate: LockEvent.Predicate) -> [LockEvent] {
        
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
