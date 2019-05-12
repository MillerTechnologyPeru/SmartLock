//
//  UnlockAction.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Bluetooth

public enum UnlockAction: UInt8, BitMaskOption {
    
    /// Unlock immediately.
    case `default` = 0b01
    
    /// Unlock when button is pressed.
    case button = 0b10
    
    public static let all: Set<UnlockAction> = [.default, .button]
}
