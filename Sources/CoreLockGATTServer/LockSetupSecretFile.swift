//
//  LockSetupSecretBase64File.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/13/18.
//
//

import Foundation
import CoreLock

/// Stores secret in base64 file.
public struct LockSetupSecretFile: LockSetupSecretStore {
    
    public let sharedSecret: KeyData
    
    public init(sharedSecret: KeyData = KeyData()) {
        
        self.sharedSecret = sharedSecret
    }
}

// MARK: - File Storage

public extension LockSetupSecretFile {
    
    init(createdAt url: URL) throws {
        
        if let file = LockSetupSecretFile(url: url) {
            
            self = file
            
        } else {
            
            self = LockSetupSecretFile()
            try write(to: url)
        }
    }
    
    init?(url: URL) {
        
        guard let base64 = try? Data(contentsOf: url),
            let data = Data(base64Encoded: base64),
            let sharedSecret = KeyData(data: data)
            else { return nil }
        
        self.init(sharedSecret: sharedSecret)
    }
    
    func write(to url: URL) throws {
        
        try sharedSecret.data
            .base64EncodedData()
            .write(to: url)
    }
}
