//
//  DeviceInformationService.swift
//  gattserver
//
//  Created by Carlos Duclos on 7/2/18.
//

import Foundation
import Bluetooth
import GATT

public final class GATTDeviceInformationServiceController <Peripheral: PeripheralProtocol> : GATTServiceController {
    
    public static var service: BluetoothUUID { return .deviceInformation }
    
    public let characteristics: Set<BluetoothUUID>
    
    // MARK: - Properties
    
    public let peripheral: Peripheral
    
    public let manufacturerName: GATTManufacturerNameString = "Miller Technology"
    
    public private(set) var modelNumber: GATTModelNumber = "" {
        didSet { peripheral[characteristic: modelNumberHandle] = modelNumber.data }
    }
    
    public private(set) var serialNumber: GATTSerialNumberString = "" {
        didSet { peripheral[characteristic: serialNumberHandle] = serialNumber.data }
    }
    
    public private(set) var firmwareRevision: GATTFirmwareRevisionString = "" {
        didSet { peripheral[characteristic: firmwareRevisionHandle] = firmwareRevision.data }
    }
    
    public private(set) var softwareRevision: GATTSoftwareRevisionString = "" {
        didSet { peripheral[characteristic: softwareRevisionHandle] = softwareRevision.data }
    }
    
    public private(set) var hardwareRevision: GATTHardwareRevisionString = "" {
        didSet { peripheral[characteristic: hardwareRevisionHandle] = hardwareRevision.data }
    }
    
    internal let serviceHandle: UInt16
    
    internal let modelNumberHandle: UInt16
    internal let serialNumberHandle: UInt16
    internal let manufacturerNameHandle: UInt16
    internal let firmwareRevisionHandle: UInt16
    internal let softwareRevisionHandle: UInt16
    internal let hardwareRevisionHandle: UInt16
    
    // MARK: - Initialization
    
    public init(peripheral: Peripheral) throws {
        
        self.peripheral = peripheral
        
        #if os(macOS)
        let serviceUUID = BluetoothUUID()
        #else
        let serviceUUID = type(of: self).service
        #endif
        
        #if os(Linux)
        let descriptors = [GATTClientCharacteristicConfiguration().descriptor]
        #else
        let descriptors: [GATT.Descriptor] = []
        #endif
        
        let characteristics = [
            
            GATT.Characteristic(uuid: type(of: manufacturerName).uuid,
                                value: manufacturerName.data,
                                permissions: [.read],
                                properties: [.read],
                                descriptors: descriptors),
            
            GATT.Characteristic(uuid: type(of: modelNumber).uuid,
                                value: modelNumber.data,
                                permissions: [.read],
                                properties: [.read],
                                descriptors: descriptors),
            
            GATT.Characteristic(uuid: type(of: serialNumber).uuid,
                                value: serialNumber.data,
                                permissions: [.read],
                                properties: [.read],
                                descriptors: descriptors),
            
            GATT.Characteristic(uuid: type(of: firmwareRevision).uuid,
                                value: firmwareRevision.data,
                                permissions: [.read],
                                properties: [.read],
                                descriptors: descriptors),
            
            GATT.Characteristic(uuid: type(of: softwareRevision).uuid,
                                value: softwareRevision.data,
                                permissions: [.read],
                                properties: [.read],
                                descriptors: descriptors),
            
            GATT.Characteristic(uuid: type(of: hardwareRevision).uuid,
                                value: hardwareRevision.data,
                                permissions: [.read],
                                properties: [.read],
                                descriptors: descriptors)
        ]
        
        self.characteristics = Set(characteristics.map { $0.uuid })
        
        let service = GATT.Service(uuid: serviceUUID,
                                   primary: true,
                                   characteristics: characteristics)
        
        self.serviceHandle = try peripheral.add(service: service)
        
        self.modelNumberHandle = peripheral.characteristics(for: type(of: modelNumber).uuid)[0]
        self.serialNumberHandle = peripheral.characteristics(for: type(of: serialNumber).uuid)[0]
        self.manufacturerNameHandle = peripheral.characteristics(for: type(of: manufacturerName).uuid)[0]
        self.firmwareRevisionHandle = peripheral.characteristics(for: type(of: firmwareRevision).uuid)[0]
        self.softwareRevisionHandle = peripheral.characteristics(for: type(of: softwareRevision).uuid)[0]
        self.hardwareRevisionHandle = peripheral.characteristics(for: type(of: hardwareRevision).uuid)[0]
    }
    
    deinit {
        
        self.peripheral.remove(service: serviceHandle)
    }
    
    // MARK: - Methods
    
    public func willRead(_ request: GATTReadRequest<Peripheral.Central>) -> ATT.Error? {
        
        return nil
    }
    
    public func willWrite(_ request: GATTWriteRequest<Peripheral.Central>) -> ATT.Error? {
        
        return nil
    }
    
    public func didWrite(_ request: GATTWriteConfirmation<Peripheral.Central>) {
        
        
    }
}
