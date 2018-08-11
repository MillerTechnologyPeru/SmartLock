//
//  DeviceManager.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/8/18.
//

import Foundation
import Bluetooth
import GATT

/// SmartLock GATT Central client.
public final class SmartLockDeviceManager <Central: CentralProtocol> {
    
    public typealias Peripheral = Central.Peripheral
    
    public typealias Advertisement = Central.Advertisement
    
    // MARK: - Initialization
    
    public init(central: Central) {
        
        self.central = central
    }
    
    // MARK: - Properties
    
    /// GATT Central Manager.
    public let central: Central
    
    /// The log message handler.
    public var log: ((String) -> ())? {
        
        get { return central.log }
        
        set { central.log = newValue }
    }
    
    /// Scans for nearby devices.
    ///
    /// - Parameter duration: The duration of the scan.
    ///
    /// - Parameter event: Callback for a found device.
    public func scan(duration: TimeInterval,
                     timeout: TimeInterval,
                     filterDuplicates: Bool = true) throws {
        
        let scanResults = try central.scan(duration: duration, filterDuplicates: filterDuplicates)
    }
    
    // MARK: - Private Methods
    
    
}
