//
//  UnsafeDataConvertible.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth

/// Internal Data casting protocol
internal protocol UnsafeDataConvertible {
    static func + (lhs: Data, rhs: Self) -> Data
    static func += (lhs: inout Data, rhs: Self)
}

extension UnsafeDataConvertible {
    public static func + (lhs: Data, rhs: Self) -> Data {
        var value = rhs
        let data = Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
        return lhs + data
    }
    
    public static func += (lhs: inout Data, rhs: Self) {
        lhs = lhs + rhs
    }
}

extension UInt8  : UnsafeDataConvertible { }
extension UInt16 : UnsafeDataConvertible { }
extension UInt32 : UnsafeDataConvertible { }
extension UInt64 : UnsafeDataConvertible { }
extension UInt128 : UnsafeDataConvertible { }

extension Int    : UnsafeDataConvertible { }
extension Float  : UnsafeDataConvertible { }
extension Double : UnsafeDataConvertible { }

extension String: UnsafeDataConvertible {
    public static func + (lhs: Data, rhs: String) -> Data {
        guard let data = rhs.data(using: .utf8) else { return lhs }
        return lhs + data
    }
}

extension Data : UnsafeDataConvertible {
    public static func + (lhs: Data, rhs: Data) -> Data {
        var data = Data()
        data.append(lhs)
        data.append(rhs)
        
        return data
    }
}
