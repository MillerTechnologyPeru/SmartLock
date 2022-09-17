//
//  GATTServiceController.swift
//  lockd
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth
import GATT
import CoreLock

public protocol GATTServiceController: AnyObject {
    
    associatedtype Peripheral: PeripheralManager
    
    static var service: BluetoothUUID { get }
    
    var peripheral: Peripheral { get }
    
    init(peripheral: Peripheral) async throws
    
    func willRead(_ request: GATTReadRequest<Peripheral.Central>) -> ATTError?
    
    func willWrite(_ request: GATTWriteRequest<Peripheral.Central>) -> ATTError?
    
    func didWrite(_ request: GATTWriteConfirmation<Peripheral.Central>) async
}

public extension GATTServiceController {
    
    func willRead(_ request: GATTReadRequest<Peripheral.Central>) -> ATTError? {
        return nil
    }
    
    func willWrite(_ request: GATTWriteRequest<Peripheral.Central>) -> ATTError? {
        return nil
    }
    
    func didWrite(_ request: GATTWriteConfirmation<Peripheral.Central>) { }
}
