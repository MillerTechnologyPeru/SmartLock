//
//  LockSetupSecretBase64File.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/13/18.
//
//

import Foundation
import CoreLock

/// Stores secret in base64
public struct LockSetupSecretBase64File: LockSetupSecretStore {
    
    public let sharedSecret: KeyData
    
    public init(sharedSecret: KeyData = KeyData()) {
        
        self.sharedSecret = sharedSecret
    }
}

// MARK: - File Storage

public extension LockSetupSecretBase64File {
    
    public init(createdAt url: URL) throws {
        
        if let file = LockSetupSecretBase64File(url: url) {
            
            self = file
            
        } else {
            
            self = LockSetupSecretBase64File()
            try write(to: url)
        }
    }
    
    public init?(url: URL) {
        
        guard let base64 = try? Data(contentsOf: url),
            let data = Data(base64Encoded: base64),
            let sharedSecret = KeyData(data: data)
            else { return nil }
        
        self.init(sharedSecret: sharedSecret)
    }
    
    public func write(to url: URL) throws {
        
        try sharedSecret.data
            .base64EncodedData()
            .write(to: url)
    }
}
