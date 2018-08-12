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
    case setup = 0x00
    
    /// Idle / Unlock Mode
    case unlock = 0x01
}
