import XCTest
@testable import CoreLockTests

XCTMain([
    testCase(CryptoTests.allTests),
    testCase(GATTProfileTests.allTests),
])
