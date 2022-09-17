//
//  UnlockState.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

public enum UnlockState: UInt8, BitMaskOption {
    
    /// Unlocked.
    case open = 0b01
    
    /// Locked.
    case close = 0b10
    
    public static let all: Set<UnlockState> = [.open, .close]
}
