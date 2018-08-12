//
//  CryptoTests.swift
//  MillerTechnology
//
//  Created by Alsey Coleman Miller on 8/11/18.
//  Copyright © 2018 MillerTechnology. All rights reserved.
//

import Foundation
import XCTest
@testable import CoreLock

final class CryptoTests: XCTestCase {
    
    static var allTests = [
        ("testHMAC", testHMAC),
        ]
    
    func testHMAC() {
        
        let key = KeyData()
        
        let nonce = Nonce()
        
        let timestamp = Date()
        
        let message = AuthenticationMessage(date: timestamp, nonce: nonce)
        
        let hmac = HMAC(key: key, message: message)
        
        print(hmac.data, Array(hmac.data))
        
        XCTAssert(hmac.data == HMAC(key: key, message: message).data, "Values must be consistent")
    }
    
    func testEncrypt() {
        
        let key = KeyData()
        
        let nonce = Nonce()
        
        let (encryptedData, iv) = encrypt(key: key.data, data: nonce.data)
        
        let decryptedData = decrypt(key: key.data, iv: iv, data: encryptedData)
        
        XCTAssert(nonce.data == decryptedData)
    }
    
    func testFailEncrypt() {
        
        let key = KeyData()
        
        let key2 = KeyData()
        
        let nonce = Nonce()
        
        let (encryptedData, iv) = encrypt(key: key.data, data: nonce.data)
        
        let decryptedData = decrypt(key: key2.data, iv: iv, data: encryptedData)
        
        XCTAssert(nonce.data != decryptedData)
    }
    
    func testEncryptKeyData() {
        
        let key = KeyData()
        
        let salt = KeyData()
        
        let (encryptedData, iv) = encrypt(key: salt.data, data: key.data)
        
        print("Encrypted key is \(encryptedData.count) bytes")
        
        let decryptedData = decrypt(key: salt.data, iv: iv, data: encryptedData)
        
        XCTAssert(decryptedData == key.data)
    }
}
