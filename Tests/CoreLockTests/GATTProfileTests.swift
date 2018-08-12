//
//  GATTProfileTests.swift
//  CoreLockTests
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import XCTest
import Bluetooth
@testable import CoreLock

final class GATTProfileTests: XCTestCase {

    func testInformation() {
        
        let information = InformationCharacteristic(identifier: UUID(),
                                                    status: .setup)
        
        guard let decoded = InformationCharacteristic(data: information.data)
            else { XCTFail("Could not parse bytes"); return }
        
        XCTAssertEqual(decoded.identifier, information.identifier)
        XCTAssertEqual(decoded.buildVersion, information.buildVersion)
        XCTAssertEqual(decoded.version, information.version)
        XCTAssertEqual(decoded.status, information.status)
        XCTAssertEqual(decoded.unlockActions, information.unlockActions)
    }
    
    func testUnlock() {
        
        let key = (identifier: UUID(), secret: KeyData())
        
        let authentication = Authentication(key: key.secret)
        
        let characteristic = UnlockCharacteristic(identifier: key.identifier, authentication: authentication)
        
        guard let decoded = UnlockCharacteristic(data: characteristic.data)
            else { XCTFail("Could not parse bytes"); return }
        
        XCTAssertEqual(decoded.authentication.data, authentication.data)
        XCTAssertEqual(decoded.identifier, characteristic.identifier)
        XCTAssertEqual(decoded.action, characteristic.action)
        
        XCTAssert(decoded.authentication.isAuthenticated(with: key.secret))
    }
    
    func testSetup() {
        
        
    }
}
