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
    
    func testHMAC() {
        
        let id = UUID()
        let key = KeyData()
        let nonce = Nonce()
        let timestamp = Date()
        let message = AuthenticationMessage(date: timestamp, nonce: nonce, digest: Digest(hash: Data()), id: id)
        let authentication = Authentication(key: key, message: message)
        XCTAssert(authentication.isAuthenticated(using: key), "Values must be consistent")
    }
    
    func testEncrypt() throws {
        
        let id = UUID()
        let key = KeyData()
        let randomData = KeyData().data
        let timestamp = Date()
        let nonce = Nonce()
        let message = AuthenticationMessage(date: timestamp, nonce: nonce, digest: Digest(hash: randomData), id: id)
        let encryptedData = try encrypt(randomData, using: key, nonce: nonce, authentication: message)
        let decryptedData = try decrypt(encryptedData, using: key, authentication: message)
        XCTAssertEqual(randomData, decryptedData)
    }
    
    func testFailEncrypt() throws {
        
        let key = KeyData()
        let key2 = KeyData()
        XCTAssertNotEqual(key, key2)
        let id = UUID()
        let randomData = KeyData().data
        let timestamp = Date()
        let nonce = Nonce()
        let message = AuthenticationMessage(date: timestamp, nonce: nonce, digest: Digest(hash: randomData), id: id)
        let encryptedData = try encrypt(randomData, using: key, nonce: nonce, authentication: message)
        XCTAssertThrowsError(try decrypt(encryptedData, using: key2, authentication: message))
    }
    
    func testNonce() {
        (0 ... 100).forEach { _ in XCTAssertNotEqual(Nonce(), Nonce()) }
    }
}
