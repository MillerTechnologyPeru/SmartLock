//
//  ResultCode.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

/// Smart Lock Result Code
public enum ErrorResponse: UInt8, Error {
    
    /// Operation performed successfully
    case success                    = 0x00
    
    /// Operation could not be completed due to authentication error.
    case invalidAuthentication      = 0x01
}
