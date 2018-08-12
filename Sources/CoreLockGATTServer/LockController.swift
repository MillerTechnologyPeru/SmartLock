//
//  SmartLockController.swift
//  lockd
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

#if os(Linux)
import Glibc
#elseif os(macOS)
import Darwin
#endif

import Foundation
import Bluetooth
import GATT
import CoreLock

/// Smart Lock GATT Server controller.
public final class LockController <Peripheral: PeripheralProtocol> {
    
    // MARK: - Properties
    
    public let peripheral: Peripheral
    
    public let lockServiceController: LockServiceController <Peripheral>
    
    // MARK: - Initialization
    
    public init(peripheral: Peripheral) throws {
        
        self.peripheral = peripheral
        
        // load services
        self.lockServiceController = try LockServiceController(peripheral: peripheral)
        
        // set callbacks
        self.peripheral.willRead = { [unowned self] in self.willRead($0) }
        self.peripheral.willWrite = { [unowned self] in return self.willWrite($0) }
        self.peripheral.didWrite = { [unowned self] in self.didWrite($0) }
    }
    
    // MARK: - Methods
    
    private func willRead(_ request: GATTReadRequest<Peripheral.Central>) -> ATT.Error? {
        
        if lockServiceController.supportsCharacteristic(request.uuid) {
            
            return lockServiceController.willRead(request)
            
        } else {
            
            return nil
        }
    }
    
    private func willWrite(_ request: GATTWriteRequest<Peripheral.Central>) -> ATT.Error? {
        
        if lockServiceController.supportsCharacteristic(request.uuid) {
            
            return lockServiceController.willWrite(request)
            
        } else {
            
            return nil
        }
    }
    
    private func didWrite(_ confirmation: GATTWriteConfirmation<Peripheral.Central>) {
        
        if lockServiceController.supportsCharacteristic(confirmation.uuid) {
            
            lockServiceController.didWrite(confirmation)
        }
    }
}

private extension GATTServiceController {
    
    func supportsCharacteristic(_ characteristicUUID: BluetoothUUID) -> Bool {
        
        return type(of: self).service.characteristics.contains(where: { $0.uuid == characteristicUUID })
    }
}
