//
//  DeviceInformationService.swift
//  gattserver
//
//  Created by Carlos Duclos on 7/2/18.
//

import Foundation
import Bluetooth
import GATT
import CoreLock

public final class GATTDeviceInformationServiceController <Peripheral: PeripheralManager> : GATTServiceController {
    
    public static var service: BluetoothUUID { return .deviceInformation }
    
    public let characteristics: Set<BluetoothUUID>
    
    // MARK: - Properties
    
    public let peripheral: Peripheral
    
    public private(set) var hardware: LockHardware = .empty
    
    public let manufacturerName: GATTManufacturerNameString = "Miller Technology"
    
    public let firmwareRevision = GATTFirmwareRevisionString(rawValue: "\(LockBuildVersion.current)")
    
    public let softwareRevision = GATTSoftwareRevisionString(rawValue: "\(LockVersion.current)")
    
    public private(set) var modelNumber: GATTModelNumber = ""
    
    public private(set) var serialNumber: GATTSerialNumberString = ""
    
    public private(set) var hardwareRevision: GATTHardwareRevisionString = ""
    
    internal let serviceHandle: UInt16
    
    internal let modelNumberHandle: UInt16
    internal let serialNumberHandle: UInt16
    internal let manufacturerNameHandle: UInt16
    internal let firmwareRevisionHandle: UInt16
    internal let softwareRevisionHandle: UInt16
    internal let hardwareRevisionHandle: UInt16
    
    // MARK: - Initialization
    
    public init(peripheral: Peripheral) async throws {
        
        self.peripheral = peripheral
        
        #if os(macOS)
        let serviceUUID = BluetoothUUID()
        #else
        let serviceUUID = type(of: self).service
        #endif
        
        let descriptors: [GATTAttribute.Descriptor] = []
        
        let characteristics = [
            
            GATTAttribute.Characteristic(uuid: type(of: manufacturerName).uuid,
                                value: manufacturerName.data,
                                permissions: [.read],
                                properties: [.read],
                                descriptors: descriptors),
            
            GATTAttribute.Characteristic(uuid: type(of: modelNumber).uuid,
                                value: modelNumber.data,
                                permissions: [.read],
                                properties: [.read],
                                descriptors: descriptors),
            
            GATTAttribute.Characteristic(uuid: type(of: serialNumber).uuid,
                                value: serialNumber.data,
                                permissions: [.read],
                                properties: [.read],
                                descriptors: descriptors),
            
            GATTAttribute.Characteristic(uuid: type(of: firmwareRevision).uuid,
                                value: firmwareRevision.data,
                                permissions: [.read],
                                properties: [.read],
                                descriptors: descriptors),
            
            GATTAttribute.Characteristic(uuid: type(of: softwareRevision).uuid,
                                value: softwareRevision.data,
                                permissions: [.read],
                                properties: [.read],
                                descriptors: descriptors),
            
            GATTAttribute.Characteristic(uuid: type(of: hardwareRevision).uuid,
                                value: hardwareRevision.data,
                                permissions: [.read],
                                properties: [.read],
                                descriptors: descriptors)
        ]
        
        self.characteristics = Set(characteristics.map { $0.uuid })
        
        let service = GATTAttribute.Service(
            uuid: serviceUUID,
            primary: true,
            characteristics: characteristics
        )
        
        self.serviceHandle = try await peripheral.add(service: service)
        
        self.modelNumberHandle = await peripheral.characteristics(for: type(of: modelNumber).uuid)[0]
        self.serialNumberHandle = await peripheral.characteristics(for: type(of: serialNumber).uuid)[0]
        self.manufacturerNameHandle = await peripheral.characteristics(for: type(of: manufacturerName).uuid)[0]
        self.firmwareRevisionHandle = await peripheral.characteristics(for: type(of: firmwareRevision).uuid)[0]
        self.softwareRevisionHandle = await peripheral.characteristics(for: type(of: softwareRevision).uuid)[0]
        self.hardwareRevisionHandle = await peripheral.characteristics(for: type(of: hardwareRevision).uuid)[0]
    }
    
    // MARK: - Methods
    
    func supportsCharacteristic(_ characteristicUUID: BluetoothUUID) -> Bool {
        let characteristics: [GATTCharacteristic.Type] = [
            GATTManufacturerNameString.self,
            GATTFirmwareRevisionString.self,
            GATTSoftwareRevisionString.self,
            GATTSerialNumberString.self,
            GATTModelNumber.self,
            GATTHardwareRevisionString.self,
        ]
        return characteristics.contains(where: { $0.uuid == characteristicUUID })
    }
    
    public func setHardware(_ newValue: LockHardware) async {
        self.hardware = newValue
        await updateInformation()
    }
    
    private func updateInformation() async {
        
        modelNumber = GATTModelNumber(rawValue: hardware.model.rawValue)
        await peripheral.write(modelNumber.data, forCharacteristic: modelNumberHandle)
        serialNumber = GATTSerialNumberString(rawValue: hardware.serialNumber)
        await peripheral.write(serialNumber.data, forCharacteristic: serialNumberHandle)
        hardwareRevision = GATTHardwareRevisionString(rawValue: hardware.hardwareRevision)
        await peripheral.write(hardwareRevision.data, forCharacteristic: hardwareRevisionHandle)
    }
}
