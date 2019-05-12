//
//  EncryptedData.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

public struct EncryptedData {
    
    internal static let minimumLength = Authentication.length + InitializationVector.length
    
    /// HMAC signature, signed by secret.
    public let authentication: Authentication
    
    /// Crypto IV
    public let initializationVector: InitializationVector
    
    /// Encrypted data
    public let encryptedData: Data
}

public extension EncryptedData {
    
    init(encrypt data: Data, with key: KeyData) throws {
        
        do {
            
            let (encryptedData, iv) = try CoreLock.encrypt(key: key.data, data: data)
            
            self.authentication = Authentication(key: key)
            self.initializationVector = iv
            self.encryptedData = encryptedData
        }
        
        catch { throw AuthenticationError.encryptionError(error) }
    }
    
    func decrypt(with key: KeyData) throws -> Data {
        
        guard authentication.isAuthenticated(with: key)
            else { throw AuthenticationError.invalidAuthentication }
        
        // attempt to decrypt
        do { return try CoreLock.decrypt(key: key.data, iv: initializationVector, data: encryptedData) }
            
        catch { throw AuthenticationError.decryptionError(error) }
    }
}

public extension EncryptedData {
    
    init?(data: Data) {
        
        guard data.count > type(of: self).minimumLength
            else { return nil }
        
        var offset = 0
        
        guard let authentication = Authentication(data: data.subdata(in: offset ..< offset + Authentication.length))
            else { assertionFailure("Could not initialize authentication"); return nil }
        
        offset += Authentication.length
        
        guard let iv = InitializationVector(data: data.subdata(in: offset ..< offset + InitializationVector.length))
            else { assertionFailure("Could not initialize IV"); return nil }
        
        offset += InitializationVector.length
        
        self.authentication = authentication
        self.initializationVector = iv
        self.encryptedData = Data(data.suffix(from: offset))
        
        assert(offset == type(of: self).minimumLength)
    }
    
    var data: Data {
        
        return authentication.data + initializationVector.data + encryptedData
    }
}
