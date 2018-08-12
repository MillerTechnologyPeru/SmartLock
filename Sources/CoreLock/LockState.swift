//
//  UnlockState.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Bluetooth

public enum UnlockState: UInt8, BitMaskOption {
    
    #if swift(>=3.2)
    #elseif swift(>=3.0)
    public typealias RawValue = UInt8
    #endif
    
    /// Unlocked.
    case open = 0b01
    
    /// Locked.
    case close = 0b10
    
    public static let all: Set<UnlockState> = [.open, .close]
}
