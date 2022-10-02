//
//  LockEventsFile.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 9/1/19.
//

import Foundation
import CoreLock
import CoreLockGATTServer

/// Stores the lock events in a JSON file.
public final class LockEventsFile: LockEventStore {
    
    typealias Events = [LockEvent]
    
    // MARK: - Properties
    
    public let url: URL
    
    public let limit: UInt
    
    // MARK: - Initialization
    
    public init(url: URL, limit: UInt = 256) {
        self.url = url
        self.limit = limit
    }
    
    // MARK: - Methods
    
    public func fetch(_ fetchRequest: LockEvent.FetchRequest) async throws -> [LockEvent] {
        return try await load { $0.fetch(fetchRequest) }
    }
    
    public func save(_ event: LockEvent) async throws {
        try await load {
            $0.append(event)
            $0.sort(by: { $0.date > $1.date })
            if $0.count > Int(limit) {
                $0 = Events($0.prefix(Int(limit)))
            }
        }
    }
    
    private func load<T>(
        _ block: (inout Events) -> (T)
    ) async throws -> T {
        
        // create or load file
        let file = try await JSONFile<Events>(url: url, defaultValue: .init())
        // load old value
        var value = await file.value
        // mutate
        let result = block(&value)
        // save if changed
        let newFileValue = await file.value
        if value != newFileValue {
            try await file.write(value)
        }
        return result
    }
}
