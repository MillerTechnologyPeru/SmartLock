//
//  GATTServiceController.swift
//  lockd
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth
import GATT

public protocol GATTServiceController: AnyObject {
    
    associatedtype Peripheral: PeripheralProtocol
    
    static var service: BluetoothUUID { get }
    
    var characteristics: Set<BluetoothUUID> { get }
    
    var peripheral: Peripheral { get }
    
    init(peripheral: Peripheral) throws
    
    func willRead(_ request: GATTReadRequest<Peripheral.Central>) -> ATT.Error?
    
    func willWrite(_ request: GATTWriteRequest<Peripheral.Central>) -> ATT.Error?
    
    func didWrite(_ request: GATTWriteConfirmation<Peripheral.Central>)
}

public extension GATTServiceController {
    
    func willRead(_ request: GATTReadRequest<Peripheral.Central>) -> ATT.Error? {
        return nil
    }
    
    func willWrite(_ request: GATTWriteRequest<Peripheral.Central>) -> ATT.Error? {
        return nil
    }
    
    func didWrite(_ request: GATTWriteConfirmation<Peripheral.Central>) { }
}
