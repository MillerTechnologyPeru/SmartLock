//
//  Status.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 4/16/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation

/// Lock status
public enum Status: UInt8 {
    
    /// Initial Status
    case setup
    
    /// Idle / Unlock Mode
    case unlock
}

// MARK: - DataConvertible

public extension Status {
    
    public init?(data: Data) {
        
        guard data.count == 1
            else { return nil }
        
        self.init(rawValue: data[0])
    }
    
    public func toData() -> Data {
        
        return Data([rawValue])
    }
}
