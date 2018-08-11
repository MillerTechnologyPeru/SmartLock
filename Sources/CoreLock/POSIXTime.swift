//
//  POSIXTime.swift
//  SwiftFoundation
//
//  Created by Alsey Coleman Miller on 7/19/15.
//  Copyright © 2015 PureSwift. All rights reserved.
//

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    import Darwin.C
#elseif os(Linux)
    import Glibc
#endif

internal extension timeval {
    
    static func timeOfDay() -> timeval {
        
        var timeStamp = timeval()
        
        guard gettimeofday(&timeStamp, nil) == 0
            else { fatalError("gettimeofday() failed") }
        
        return timeStamp
    }
    
    init(timeInterval: Double) {
        
        let (integerValue, decimalValue) = modf(timeInterval)
        
        let million: Double = 1000000.0
        
        let microseconds = decimalValue * million
        
        self.init(tv_sec: Int(integerValue), tv_usec: POSIXMicroseconds(microseconds))
    }
    
    var timeInterval: Double {
        
        let secondsSince1970 = Double(self.tv_sec)
        
        let million: Double = 1000000.0
        
        let microseconds = Double(self.tv_usec) / million
        
        return secondsSince1970 + microseconds
    }
}

public extension timespec {
    
    init(timeInterval: Double) {
        
        let (integerValue, decimalValue) = modf(timeInterval)
        
        let billion: Double = 1000000000.0
        
        let nanoseconds = decimalValue * billion
        
        self.init(tv_sec: Int(integerValue), tv_nsec: Int(nanoseconds))
    }
    
    var timeInterval: Double {
        
        let secondsSince1970 = Double(self.tv_sec)
        
        let billion: Double = 1000000000.0
        
        let nanoseconds = Double(self.tv_nsec) / billion
        
        return secondsSince1970 + nanoseconds
    }
}

internal extension tm {
    
    init(UTCSecondsSince1970: time_t) {
        
        var seconds = UTCSecondsSince1970
        
        // don't free!
        // The return value points to a statically allocated struct which might be overwritten by subsequent calls to any of the date and time functions.
        // http://linux.die.net/man/3/gmtime
        let timePointer = gmtime(&seconds)!
        
        self = timePointer.pointee
    }
}

// MARK: - Cross-Platform Support

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    
    internal typealias POSIXMicroseconds = __darwin_suseconds_t
    
#elseif os(Linux)
    
    internal typealias POSIXMicroseconds = __suseconds_t
    
    internal func modf(value: Double) -> (Double, Double) {
        
        var integerValue: Double = 0
        
        let decimalValue = modf(value, &integerValue)
        
        return (decimalValue, integerValue)
    }
    
#endif
