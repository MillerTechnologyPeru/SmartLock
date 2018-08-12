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
}
