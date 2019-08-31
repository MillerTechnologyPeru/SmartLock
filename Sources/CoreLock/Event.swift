//
//  Event.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/31/19.
//

import Foundation

public enum LockEvent: Equatable {
    
    case setup(Setup)
    case unlock(Unlock)
    case createNewKey(CreateNewKey)
    case confirmNewKey(ConfirmNewKey)
}

public extension LockEvent {
    
    var identifier: UUID {
        switch self {
        case let .setup(event):
            return event.identifier
        case let .unlock(event):
            return event.identifier
        case let .createNewKey(event):
            return event.identifier
        case let .confirmNewKey(event):
            return event.identifier
        }
    }
    
    var date: Date {
        switch self {
        case let .setup(event):
            return event.date
        case let .unlock(event):
            return event.date
        case let .createNewKey(event):
            return event.date
        case let .confirmNewKey(event):
            return event.date
        }
    }
    
    var lock: UUID {
        switch self {
        case let .setup(event):
            return event.lock
        case let .unlock(event):
            return event.lock
        case let .createNewKey(event):
            return event.lock
        case let .confirmNewKey(event):
            return event.lock
        }
    }
}

// MARK: - Codable

extension LockEvent: Codable {
    
    internal enum CodingKeys: String, CodingKey {
        case type
        case event
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EventType.self, forKey: .type)
        switch type {
        case .setup:
            let event = try container.decode(Setup.self, forKey: .event)
            self = .setup(event)
        case .unlock:
            let event = try container.decode(Unlock.self, forKey: .event)
            self = .unlock(event)
        case .createNewKey:
            let event = try container.decode(CreateNewKey.self, forKey: .event)
            self = .createNewKey(event)
        case .confirmNewKey:
            let event = try container.decode(ConfirmNewKey.self, forKey: .event)
            self = .confirmNewKey(event)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        switch self {
        case let .setup(event):
            try container.encode(event, forKey: .event)
        case let .unlock(event):
            try container.encode(event, forKey: .event)
        case let .createNewKey(event):
            try container.encode(event, forKey: .event)
        case let .confirmNewKey(event):
            try container.encode(event, forKey: .event)
        }
    }
}

// MARK: - Supporting Types

public extension LockEvent {
    
    enum EventType: String, Codable {
        
        case setup = "com.colemancda.Lock.Event.Setup"
        case unlock = "com.colemancda.Lock.Event.Unlock"
        case createNewKey = "com.colemancda.Lock.Event.CreateNewKey"
        case confirmNewKey = "com.colemancda.Lock.Event.ConfirmNewKey"
    }
    
    var type: EventType {
        
        switch self {
        case .setup:            return .setup
        case .unlock:           return .unlock
        case .createNewKey:     return .createNewKey
        case .confirmNewKey:    return .confirmNewKey
        }
    }
}

public extension LockEvent {
    
    struct Setup: Codable, Equatable {
        
        public let identifier: UUID
        
        public let date: Date
        
        public let lock: UUID
        
        public let key: Key
        
        public init(identifier: UUID = UUID(),
                    date: Date = Date(),
                    lock: UUID,
                    key: Key) {
            self.identifier = identifier
            self.date = date
            self.lock = lock
            self.key = key
        }
    }
    
    struct Unlock: Codable, Equatable {
        
        public let identifier: UUID
        
        public let date: Date
        
        public let lock: UUID
        
        public let key: Key
        
        public let action: UnlockAction
        
        public init(identifier: UUID = UUID(),
                    date: Date = Date(),
                    lock: UUID,
                    key: Key,
                    action: UnlockAction = .default) {
            self.identifier = identifier
            self.date = date
            self.lock = lock
            self.key = key
            self.action = action
        }
    }
    
    struct CreateNewKey: Codable, Equatable {
        
        public let identifier: UUID
        
        public let date: Date
        
        public let lock: UUID
        
        public let key: Key
        
        public let newKey: NewKey
        
        public init(identifier: UUID = UUID(),
                    date: Date = Date(),
                    lock: UUID,
                    key: Key,
                    newKey: NewKey) {
            self.identifier = identifier
            self.date = date
            self.lock = lock
            self.key = key
            self.newKey = newKey
        }
    }
    
    struct ConfirmNewKey: Codable, Equatable {
        
        public let identifier: UUID
        
        public let date: Date
        
        public let lock: UUID
        
        /// The new key invitation.
        public let newKey: NewKey
        
        /// The newly created key.
        public let key: Key
        
        public init(identifier: UUID = UUID(),
                    date: Date = Date(),
                    lock: UUID,
                    newKey: NewKey,
                    key: Key) {
            self.identifier = identifier
            self.date = date
            self.lock = lock
            self.newKey = newKey
            self.key = key
        }
    }
}
