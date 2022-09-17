//
//  Event.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/31/19.
//

import Foundation
import TLVCoding

public enum LockEvent: Equatable {
    
    case setup(Setup)
    case unlock(Unlock)
    case createNewKey(CreateNewKey)
    case confirmNewKey(ConfirmNewKey)
    case removeKey(RemoveKey)
}

public extension LockEvent {
    
    var id: UUID {
        switch self {
        case let .setup(event):
            return event.id
        case let .unlock(event):
            return event.id
        case let .createNewKey(event):
            return event.id
        case let .confirmNewKey(event):
            return event.id
        case let .removeKey(event):
            return event.id
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
        case let .removeKey(event):
            return event.date
        }
    }
    
    var key: UUID {
        switch self {
        case let .setup(event):
            return event.key
        case let .unlock(event):
            return event.key
        case let .createNewKey(event):
            return event.key
        case let .confirmNewKey(event):
            return event.key
        case let .removeKey(event):
            return event.key
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
        case .removeKey:
            let event = try container.decode(RemoveKey.self, forKey: .event)
            self = .removeKey(event)
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
        case let .removeKey(event):
            try container.encode(event, forKey: .event)
        }
    }
}

// MARK: - Supporting Types

public extension LockEvent {
    
    enum EventType: String, Codable {
        
        case setup          = "com.colemancda.Lock.Event.Setup"
        case unlock         = "com.colemancda.Lock.Event.Unlock"
        case createNewKey   = "com.colemancda.Lock.Event.CreateNewKey"
        case confirmNewKey  = "com.colemancda.Lock.Event.ConfirmNewKey"
        case removeKey      = "com.colemancda.Lock.Event.RemoveKey"
    }
    
    var type: EventType {
        
        switch self {
        case .setup:            return .setup
        case .unlock:           return .unlock
        case .createNewKey:     return .createNewKey
        case .confirmNewKey:    return .confirmNewKey
        case .removeKey:        return .removeKey
        }
    }
}

extension LockEvent.EventType: TLVCodable {
    
    internal enum TLVType: UInt8 {
        case setup          = 0x01
        case unlock         = 0x02
        case createNewKey   = 0x03
        case confirmNewKey  = 0x04
        case removeKey      = 0x05
    }
    
    public init?(tlvData: Data) {
        guard tlvData.count == 1,
            let type = TLVType(rawValue: tlvData[0])
            else { return nil }
        self = unsafeBitCast(type, to: LockEvent.EventType.self)
    }
    
    public var tlvData: Data {
        let type = unsafeBitCast(self, to: TLVType.self)
        return Data([type.rawValue])
    }
}

public extension LockEvent {
    
    struct Setup: Codable, Equatable {
        
        public let id: UUID
        
        public let date: Date
        
        public let key: UUID
        
        public init(id: UUID = UUID(),
                    date: Date = Date(),
                    key: UUID) {
            
            self.id = id
            self.date = date
            self.key = key
        }
    }

    struct Unlock: Codable, Equatable {
        
        public let id: UUID
        
        public let date: Date
        
        public let key: UUID
        
        public let action: UnlockAction
        
        public init(id: UUID = UUID(),
                    date: Date = Date(),
                    key: UUID,
                    action: UnlockAction = .default) {
            
            self.id = id
            self.date = date
            self.key = key
            self.action = action
        }
    }
    
    struct CreateNewKey: Codable, Equatable {
        
        public let id: UUID
        
        public let date: Date
                
        public let key: UUID
        
        public let newKey: UUID
        
        public init(id: UUID = UUID(),
                    date: Date = Date(),
                    key: UUID,
                    newKey: UUID) {
            self.id = id
            self.date = date
            self.key = key
            self.newKey = newKey
        }
    }
    
    struct ConfirmNewKey: Codable, Equatable {
        
        public let id: UUID
        
        public let date: Date
                
        /// The new key invitation.
        public let newKey: UUID
        
        /// The newly created key.
        public let key: UUID
        
        public init(id: UUID = UUID(),
                    date: Date = Date(),
                    newKey: UUID,
                    key: UUID) {
            self.id = id
            self.date = date
            self.newKey = newKey
            self.key = key
        }
    }
    
    struct RemoveKey: Codable, Equatable {
        
        public let id: UUID
        
        public let date: Date
        
        public let key: UUID
        
        public let removedKey: UUID
        
        public let type: KeyType
        
        public init(id: UUID = UUID(),
                    date: Date = Date(),
                    key: UUID,
                    removedKey: UUID,
                    type: KeyType) {
            self.id = id
            self.date = date
            self.key = key
            self.removedKey = removedKey
            self.type = type
        }
    }
}

