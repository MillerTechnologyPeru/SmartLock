//
//  Authorization.swift
//  lockd
//
//  Created by Alsey Coleman Miller on 8/13/18.
//

import Foundation
import CoreLock
import CoreLockGATTServer

#if swift(>=3.2)
#elseif swift(>=3.0)
import Codable
#endif

final class JSONArchiveAuthorizationStore: LockAuthorizationStore {
    
    
    init(url: URL = URL(fileURLWithPath: "/opt/colemancda/lockd/data.json")) {
        
        self.url = url
        
        let filename = url.path
        
        // try load existing data...
        
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: filename) else {
            
            // no prevous data
            guard fileManager.createFile(atPath: filename, contents: nil)
                else { fatalError("Could not create Store at \(filename)") }
            return
        }
        
        loadData()
    }
    
    let url: URL
    
    private let jsonDecoder = JSONDecoder()
    private let jsonEncoder = JSONEncoder()
    
    private var database = Database()
    
    private func loadData() {
        
        guard let data = try? Data(contentsOf: url),
            let database = try? jsonDecoder.decode(Database.self, from: data)
            else { return }
        
        self.database = database
    }
    
    private func write(database changes: (inout Database) -> ()) throws {
        
        var database = self.database
        
        changes(&database)
        
        let data = try jsonEncoder.encode(database)
        
        try data.write(to: url, options: .atomic)
        
        self.database = database
    }
    
    var isEmpty: Bool {
        
        return database.keys.isEmpty
            && database.newKeys.isEmpty
    }
    
    func add(_ key: Key, secret: KeyData) throws {
        
        try write { $0.keys.append(Database.KeyEntry(key: key, secret: secret)) }
    }
    
    func key(for identifier: UUID) throws -> (key: Key, secret: KeyData)? {
        
        guard let keyEntry = database.keys.first(where: { $0.key.identifier == identifier })
            else { return nil }
        
        return (keyEntry.key, keyEntry.secret)
    }
}

extension JSONArchiveAuthorizationStore {
    
    public struct Database {
        
        public var keys: [KeyEntry]
        
        public var newKeys: [NewKeyEntry]
        
        public init() {
            
            self.keys = []
            self.newKeys = []
        }
    }
}

extension JSONArchiveAuthorizationStore.Database {
    
    public struct KeyEntry {
        
        public let key: Key
        
        public let secret: KeyData
    }
    
    public struct NewKeyEntry {
        
        public let newKey: Key
        
        /// Shared secret used for onboarding
        public let sharedSecret: KeyData
    }
}

extension JSONArchiveAuthorizationStore.Database: Codable {
    
    internal enum CodingKeys: String, CodingKey {
        
        case keys
        case newKeys
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.keys = try container.decode([KeyEntry].self, forKey: .keys)
        self.newKeys = try container.decode([NewKeyEntry].self, forKey: .newKeys)
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(keys, forKey: .keys)
        try container.encode(newKeys, forKey: .newKeys)
    }
}

extension JSONArchiveAuthorizationStore.Database.KeyEntry: Codable {
    
    internal enum CodingKeys: String, CodingKey {
        
        case key
        case secret
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.key = try container.decode(Key.self, forKey: .key)
        
        let data = try container.decode(Data.self, forKey: .secret)
        
        guard let secret = KeyData(data: data) else {
            
            throw DecodingError.typeMismatch(KeyData.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not initialize key data"))
        }
        
        self.secret = secret
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(key, forKey: .key)
        try container.encode(secret.data, forKey: .secret)
    }
}

extension JSONArchiveAuthorizationStore.Database.NewKeyEntry: Codable {
    
    internal enum CodingKeys: String, CodingKey {
        
        case newKey
        case sharedSecret
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.newKey = try container.decode(Key.self, forKey: .newKey)
        
        let data = try container.decode(Data.self, forKey: .sharedSecret)
        
        guard let secret = KeyData(data: data) else {
            
            throw DecodingError.typeMismatch(KeyData.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Could not initialize key data from \(data)"))
        }
        
        self.sharedSecret = secret
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(newKey, forKey: .newKey)
        try container.encode(sharedSecret.data, forKey: .sharedSecret)
    }
}
