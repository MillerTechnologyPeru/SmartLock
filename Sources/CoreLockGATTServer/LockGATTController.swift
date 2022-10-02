//
//  SmartLockController.swift
//  lockd
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth
import GATT
import CoreLock

/// Smart Lock GATT Server controller.
public final class LockGATTController <Peripheral: PeripheralManager> {
    
    // MARK: - Properties
    
    public let peripheral: Peripheral
    
    public let deviceInformationController: GATTDeviceInformationServiceController<Peripheral>
    
    public let lockServiceController: LockGATTServiceController<Peripheral>
    
    // MARK: - Initialization
    
    public init(peripheral: Peripheral) async throws {
        
        self.peripheral = peripheral
        
        // load services
        self.deviceInformationController = try await GATTDeviceInformationServiceController(peripheral: peripheral)
        self.lockServiceController = try await LockGATTServiceController(peripheral: peripheral)
        
        // set callbacks
        self.peripheral.willRead = { [unowned self] in
            self.willRead($0)
        }
        self.peripheral.willWrite = { [unowned self] in
            return self.willWrite($0)
        }
        self.peripheral.didWrite = { (confirmation) in
            Task(priority: .high) { [weak self] in
                await self?.didWrite(confirmation)
            }
        }
    }
    
    // MARK: - Methods
    
    public func setHardware(_ newValue: LockHardware) async {
        await deviceInformationController.setHardware(newValue)
        await lockServiceController.updateInformation()
    }
    
    private func willRead(_ request: GATTReadRequest<Peripheral.Central>) -> ATTError? {
        
        if lockServiceController.supportsCharacteristic(request.uuid) {
            return lockServiceController.willRead(request)
        } else if deviceInformationController.supportsCharacteristic(request.uuid) {
            return deviceInformationController.willRead(request)
        } else {
            return nil
        }
    }
    
    private func willWrite(_ request: GATTWriteRequest<Peripheral.Central>) -> ATTError? {
        
        if lockServiceController.supportsCharacteristic(request.uuid) {
            return lockServiceController.willWrite(request)
        } else if deviceInformationController.supportsCharacteristic(request.uuid) {
            return deviceInformationController.willWrite(request)
        } else {
            return nil
        }
    }
    
    private func didWrite(_ confirmation: GATTWriteConfirmation<Peripheral.Central>) async {
        
        if lockServiceController.supportsCharacteristic(confirmation.uuid) {
            await lockServiceController.didWrite(confirmation)
        } else if deviceInformationController.supportsCharacteristic(confirmation.uuid) {
            deviceInformationController.didWrite(confirmation)
        }
    }
}
