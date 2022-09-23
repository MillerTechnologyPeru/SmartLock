//
//  Central.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

#if canImport(CoreBluetooth) && canImport(DarwinGATT)
import Foundation
import CoreBluetooth
import Bluetooth
import GATT
import DarwinGATT

public typealias NativeCentral = DarwinCentral
public typealias NativePeripheral = DarwinCentral.Peripheral

public extension DarwinCentral {
    
    /// Wait for CoreBluetooth to be ready.
    func waitPowerOn(warning: Int = 3, timeout: Int = 10) async throws {
        
        var powerOnWait = 0
        while await state != .poweredOn {
            
            // inform user after 3 seconds
            if powerOnWait == warning {
                NSLog("Waiting for CoreBluetooth to be ready, please turn on Bluetooth")
            }
            
            try await Task.sleep(nanoseconds: 1_000_000_000)
            powerOnWait += 1
            guard powerOnWait < timeout
                else { throw LockError.bluetoothUnavailable }
        }
    }
}

#endif
