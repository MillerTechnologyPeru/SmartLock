//
//  AuthenticationMessage.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

/// HMAC Message
public struct AuthenticationMessage {
    
    internal static let length = MemoryLayout<UInt64>.size + Nonce.length
    
    public let date: Date
    
    public let nonce: Nonce
    
    public init(date: Date = Date(),
                nonce: Nonce = Nonce()) {
        
        self.date = date
        self.nonce = nonce
    }
}

public extension AuthenticationMessage {
    
    public init?(data: Data) {
        
        guard data.count == type(of: self).length
            else { return nil }
        
        let timeInterval = UInt64(littleEndian: UInt64(bytes: (data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7])))
        
        let timestamp = Date(timeIntervalSince1970: TimeInterval(bitPattern: timeInterval))
        
        guard let nonce = Nonce(data: Data(data[8 ..< 24]))
            else { assertionFailure("Could not initialize nonce"); return nil }
        
        self.date = timestamp
        self.nonce = nonce
    }
    
    public var data: Data {
        
        var data = Data(capacity: type(of: self).length)
        
        data += date.timeIntervalSince1970.bitPattern.littleEndian
        data += nonce.data
        
        assert(data.count == type(of: self).length)
        
        return data
    }
}
