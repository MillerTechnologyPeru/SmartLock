//
//  ResultCode.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

/// Smart Lock Result Code
public enum ErrorResponse: UInt8, Error {
    
    /// Operation could not be completed due to authentication error.
    case invalidAuthentication      = 0x01
}
