//
//  JSON.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/26/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public typealias JSONCodable = JSONEncodable & JSONDecodable

public protocol JSONEncodable: Encodable {
    
    static var jsonEncoder: JSONEncoder { get }
    
    func encodeJSON() -> Data
}

public extension JSONEncodable {
    
    static var jsonEncoder: JSONEncoder { return .init() }
    
    func encodeJSON() -> Data {
        do { return try type(of: self).jsonEncoder.encode(self) }
        catch { fatalError("Unable to encode JSON: \(error)") }
    }
}

public protocol JSONDecodable: Decodable {
    
    static var jsonDecoder: JSONDecoder { get }
    
    static func decodeJSON(from data: Data) throws -> Self
}

public extension JSONDecodable {
    
    static var jsonDecoder: JSONDecoder { return .init() }
    
    static func decodeJSON(from data: Data) throws -> Self {
        try self.jsonDecoder.decode(self, from: data)
    }
}
