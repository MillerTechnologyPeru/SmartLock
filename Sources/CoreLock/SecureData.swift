//
//  SecureData.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 4/16/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation

/// Secure Data Protocol. 
public protocol SecureData: Equatable {
    
    /// The data length. 
    static var length: Int { get }
    
    /// The data.
    var data: Data { get }
    
    /// Initialize with data.
    init?(data: Data)
    
    /// Initialize with random value.
    init()
}

public func == <T: SecureData> (lhs: T, rhs: T) -> Bool {
    
    return lhs.data == rhs.data
}

/// A lock's key used for unlocking and actions.
public struct KeyData: SecureData {
    
    public static let length = 256 / 8 // 32
    
    public let data: Data
    
    public init?(data: Data) {
        
        guard data.count == type(of: self).length
            else { return nil }
        
        self.data = data
    }
    
    /// Initializes a `Key` with a random value.
    public init() {
        
        self.data = random(type(of: self).length)
    }
}

/// Cryptographic nonce
public struct Nonce: SecureData {
    
    public static let length = 16
    
    public let data: Data
    
    public init?(data: Data) {
        
        guard data.count == type(of: self).length
            else { return nil }
        
        self.data = data
    }
    
    public init() {
        
        self.data = random(type(of: self).length)
    }
}

public struct InitializationVector: SecureData {
    
    public static let length = IVSize
    
    public let data: Data
    
    public init?(data: Data) {
        
        guard data.count == type(of: self).length
            else { return nil }
        
        self.data = data
    }
    
    public init() {
        
        self.data = random(type(of: self).length)
    }
}
