//
//  Central.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import Foundation
import CoreBluetooth
import Bluetooth
import GATT
import DarwinGATT

#if targetEnvironment(simulator)

public typealias NativeCentral = MockCentral
public typealias NativePeripheral = MockCentral.Peripheral

public extension NativeCentral {
    
    private struct Cache {
        static let central = MockCentral()
    }
    
    static var shared: NativeCentral {
        return Cache.central
    }
}

#else

public typealias NativeCentral = DarwinCentral
public typealias NativePeripheral = DarwinCentral.Peripheral

public extension NativeCentral {
    
    private struct Cache {
        static let central = DarwinCentral(
            options: .init(showPowerAlert: true)
        )
    }
    
    static var shared: NativeCentral {
        return Cache.central
    }
}

#endif

public extension NativeCentral {
    
    /// Wait for CoreBluetooth to be ready.
    func wait(
        for state: DarwinBluetoothState,
        warning: Int = 3,
        timeout: Int = 10
    ) async throws {
        
        var powerOnWait = 0
        while await self.state != state {
            
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
