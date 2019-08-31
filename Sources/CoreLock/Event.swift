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
    
    struct Setup: Codable, Equatable {
        
        public let date: Date
        
        public let key: Key
        
        public init(date: Date = Date(), key: Key) {
            self.date = date
            self.key = key
        }
    }
    
    struct Unlock: Codable, Equatable {
        
        public let date: Date
        
        public let key: Key
        
        public let action: UnlockAction
        
        public init(date: Date = Date(),
                    key: Key,
                    action: UnlockAction = .default) {
            self.date = date
            self.key = key
            self.action = action
        }
    }
    
    struct CreateNewKey: Codable, Equatable {
        
        public let date: Date
        
        public let key: Key
        
        public let newKey: NewKey
        
        public init(date: Date = Date(),
                    key: Key,
                    newKey: NewKey) {
            self.date = date
            self.key = key
            self.newKey = newKey
        }
    }
    
    struct ConfirmNewKey: Codable, Equatable {
        
        public let date: Date
        
        /// The new key invitation.
        public let newKey: NewKey
        
        /// The newly created key.
        public let key: Key
        
        public init(date: Date = Date(),
                    newKey: NewKey,
                    key: Key) {
            
            self.date = date
            self.newKey = newKey
            self.key = key
        }
    }
}
