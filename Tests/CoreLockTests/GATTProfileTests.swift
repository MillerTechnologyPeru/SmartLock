//
//  GATTProfileTests.swift
//  CoreLockTests
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import XCTest
import Bluetooth
import TLVCoding
@testable import CoreLock

final class GATTProfileTests: XCTestCase {

    func testInformation() {
        
        let information = LockInformationCharacteristic(
            id: UUID(),
            status: .setup
        )
        
        guard let decoded = LockInformationCharacteristic(data: information.data)
            else { XCTFail("Could not parse bytes"); return }
        
        XCTAssertEqual(information, decoded)
    }
    
    func testUnlock() async throws {
        
        for _ in 0 ..< 20 {
            
            let key = (id: UUID(), secret: KeyData())
            let request = UnlockRequest(action: .default)
            let characteristic = try UnlockCharacteristic(request: request, using: key.secret, id: key.id)
            guard let decodedCharacteristic = UnlockCharacteristic(data: characteristic.data)
                else { XCTFail("Could not parse bytes"); return }
            let decodedRequest = try decodedCharacteristic.decrypt(with: key.secret)
            XCTAssertEqual(decodedRequest, request)
            XCTAssertEqual(characteristic, decodedCharacteristic)
            XCTAssertEqual(characteristic.encryptedData.encryptedData, decodedCharacteristic.encryptedData.encryptedData)
            XCTAssertEqual(characteristic.encryptedData.authentication, decodedCharacteristic.encryptedData.authentication)
            XCTAssertEqual(characteristic.encryptedData.authentication.message, decodedCharacteristic.encryptedData.authentication.message)
            XCTAssertEqual(characteristic.encryptedData.authentication.message.nonce, decodedCharacteristic.encryptedData.authentication.message.nonce)
            XCTAssertEqual(characteristic.encryptedData.authentication.message.date, decodedCharacteristic.encryptedData.authentication.message.date)
            XCTAssertEqual(characteristic.encryptedData.authentication.message.id, decodedCharacteristic.encryptedData.authentication.message.id)
            XCTAssertEqual(characteristic.encryptedData.authentication.signedData, decodedCharacteristic.encryptedData.authentication.signedData)
            XCTAssert(decodedCharacteristic.encryptedData.authentication.isAuthenticated(using: key.secret))
            XCTAssert(characteristic.encryptedData.authentication.isAuthenticated(using: key.secret))
            XCTAssert(Authentication(key: key.secret, message: characteristic.encryptedData.authentication.message).isAuthenticated(using: key.secret))
            
            try await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    func testSetup() throws {
        
        let deviceSharedSecret = KeyData()
        let request = SetupRequest()
        let characteristic = try SetupCharacteristic(request: request, sharedSecret: deviceSharedSecret)
        
        guard let decoded = SetupCharacteristic(data: characteristic.data)
            else { XCTFail("Could not parse bytes"); return }
        
        XCTAssertEqual(try! TLVEncoder.lock.encode(decoded.encryptedData),
                       try! TLVEncoder.lock.encode(characteristic.encryptedData))
        
        let decrypted = try decoded.decrypt(using: deviceSharedSecret)
        
        XCTAssertEqual(request, decrypted)
        XCTAssertEqual(request.id, decrypted.id)
        XCTAssertEqual(request.secret, decrypted.secret)
    }
}
