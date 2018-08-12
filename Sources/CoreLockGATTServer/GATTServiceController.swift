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

public protocol GATTServiceController: class {
    
    associatedtype Peripheral: PeripheralProtocol
    
    static var service: GATTProfileService.Type { get }
    
    var peripheral: Peripheral { get }
    
    init(peripheral: Peripheral) throws
    
    func willRead(_ request: GATTReadRequest<Peripheral.Central>) -> ATT.Error?
    
    func willWrite(_ request: GATTWriteRequest<Peripheral.Central>) -> ATT.Error?
    
    func didWrite(_ request: GATTWriteConfirmation<Peripheral.Central>)
}
