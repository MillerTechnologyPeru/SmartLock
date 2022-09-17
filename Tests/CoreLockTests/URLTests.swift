//
//  URLTests.swift
//  CoreLockTests
//
//  Created by Alsey Coleman Miller on 7/12/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import XCTest
@testable import CoreLock

final class URLTests: XCTestCase {
    
    func testSetup() {
        
        let url = URL(string: "lock:/setup/25261345-ADC6-4802-882B-613AD8E86BE1/AcDIoBrCWorulJh4WBRr2z0KTWxzXt9Rz37bOqHYChA=")!
        
        guard let lockURL = LockURL(rawValue: url)
            else { XCTFail("Invalid URL"); return }
        
        XCTAssertEqual(lockURL.rawValue, url)
        
        guard case let .setup(lockIdentifier, secret) = lockURL
            else { XCTFail("Invalid URL"); return }
        
        XCTAssertEqual(lockIdentifier.uuidString, "25261345-ADC6-4802-882B-613AD8E86BE1")
        XCTAssertEqual(secret.data.base64EncodedString(), "AcDIoBrCWorulJh4WBRr2z0KTWxzXt9Rz37bOqHYChA=")
    }
}
