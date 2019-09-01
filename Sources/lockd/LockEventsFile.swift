//
//  LockEventsFile.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 9/1/19.
//

import Foundation
import CoreLock
import CoreLockGATTServer

/// Stores the lock evets in a JSON file.
public struct LockEventsFile: LockEventStore {
    
    typealias Events = [LockEvent]
    
    // MARK: - Properties
    
    public let url: URL
    
    // MARK: - Initialization
    
    public init(url: URL) {
        self.url = url
    }
    
    // MARK: - Methods
    
    public func fetch(_ fetchRequest: ListEventsCharacteristic.FetchRequest) throws -> [LockEvent] {
        return try load { $0.fetch(fetchRequest) }
    }
    
    public func save(_ event: LockEvent) throws {
        try load {
            $0.append(event)
            $0.sort(by: { $0.date > $1.date })
        }
    }
    
    private func load<T>(_ block: (inout Events) -> (T)) throws -> T {
        
        let file = try JSONFile<Events>(url: url, defaultValue: .init())
        var value = file.value
        let result = block(&value)
        if value != file.value {
            try file.write(value)
        }
        return result
    }
}
