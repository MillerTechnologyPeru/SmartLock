//
//  MockCentral.swift
//  
//
//  Created by Alsey Coleman Miller on 22/12/21.
//

#if DEBUG
import Foundation
import Bluetooth
import GATT
import DarwinGATT

public final class MockCentral: CentralManager {
    
    /// Central Peripheral Type
    public typealias Peripheral = GATT.Peripheral
    
    /// Central Advertisement Type
    public typealias Advertisement = MockAdvertisementData
    
    /// Central Attribute ID (Handle)
    public typealias AttributeID = UInt16
    
    // MARK: - Properties
    
    public var log: ((String) -> ())?
    
    public var state: DarwinBluetoothState {
        get async {
            try? await Task.sleep(timeInterval: 0.1)
            return await storage.bluetoothState
        }
    }
    
    public var peripherals: Set<GATT.Peripheral> {
        get async {
            try? await Task.sleep(timeInterval: 0.1)
            return await Set(storage.state.scanData.map { $0.peripheral })
        }
    }
    
    private let storage = Storage()
    
    // MARK: - Initialization
    
    internal init() {
        Task {
            try await Task.sleep(timeInterval: 0.5)
            await self.storage.stateDidChange(.poweredOn)
        }
    }
    
    // MARK: - Methods
    
    /// Scans for peripherals that are advertising services.
    public func scan(filterDuplicates: Bool = true) -> AsyncCentralScan<MockCentral> {
        return _scan(filterDuplicates: filterDuplicates, with: [])
    }
    
    /// Scans for peripherals that are advertising services.
    public func scan(with services: Set<BluetoothUUID>, filterDuplicates: Bool = true) -> AsyncCentralScan<MockCentral> {
        return _scan(filterDuplicates: filterDuplicates, with: services)
    }
    
    /// Scans for peripherals that are advertising services.
    private func _scan(filterDuplicates: Bool, with services: Set<BluetoothUUID>) -> AsyncCentralScan<MockCentral> {
        return AsyncCentralScan { continuation in
            let state = await self.state
            guard state == .poweredOn else {
                throw DarwinCentralError.invalidState(state)
            }
            try await Task.sleep(timeInterval: 1.0)
            for scanData in await self.storage.state.scanData {
                // apply filter
                if services.isEmpty == false {
                    let foundServiceUUIDs = scanData.advertisementData.serviceUUIDs ?? []
                    guard Set(foundServiceUUIDs.filter({ services.contains($0) })) == services else {
                        continue
                    }
                }
                try await Task.sleep(timeInterval: 0.3)
                continuation(scanData)
            }
        }
    }
    
    /// Connect to the specified device
    public func connect(to peripheral: Peripheral) async throws {
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
        let _ = await storage.updateState {
            $0.connected.insert(peripheral)
        }
    }
    
    /// Disconnect the specified device.
    public func disconnect(_ peripheral: Peripheral) {
        Task {
            await self.storage.updateState {
                $0.connected.remove(peripheral)
            }
        }
    }
    
    /// Disconnect all connected devices.
    public func disconnectAll() {
        Task {
            await storage.updateState {
                $0.connected.removeAll()
            }
        }
    }
    
    /// Discover Services
    public func discoverServices(
        _ services: Set<BluetoothUUID> = [],
        for peripheral: Peripheral
    ) async throws -> [Service<Peripheral, AttributeID>] {
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
        return await storage.state.characteristics
            .keys
            .lazy
            .filter { $0.peripheral == peripheral }
            .sorted(by: { $0.id < $1.id })
    }
    
    public func discoverIncludedServices(
        _ services: Set<BluetoothUUID> = [],
        for service: Service<Peripheral, AttributeID>
    ) async throws -> [Service<Peripheral, AttributeID>] {
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
        return []
    }
    
    /// Discover Characteristics for service
    public func discoverCharacteristics(
        _ characteristics: Set<BluetoothUUID> = [],
        for service: Service<Peripheral, AttributeID>
    ) async throws -> [Characteristic<Peripheral, AttributeID>] {
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
        guard await storage.state.connected.contains(service.peripheral) else {
            throw CentralError.disconnected
        }
        guard let characteristics = await storage.state.characteristics[service] else {
            throw CentralError.invalidAttribute(service.uuid)
        }
        return characteristics
            .sorted(by: { $0.id < $1.id })
    }
    
    /// Read Characteristic Value
    public func readValue(
        for characteristic: Characteristic<Peripheral, AttributeID>
    ) async throws -> Data {
        guard await storage.state.connected.contains(characteristic.peripheral) else {
            throw CentralError.disconnected
        }
        return await storage.state.characteristicValues[characteristic] ?? Data()
    }
    
    /// Write Characteristic Value
    public func writeValue(
        _ data: Data,
        for characteristic: Characteristic<Peripheral, AttributeID>,
        withResponse: Bool = true
    ) async throws {
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
        guard await storage.state.connected.contains(characteristic.peripheral) else {
            throw CentralError.disconnected
        }
        if withResponse {
            guard characteristic.properties.contains(.write) else {
                throw CentralError.invalidAttribute(characteristic.uuid)
            }
        } else {
            guard characteristic.properties.contains(.writeWithoutResponse) else {
                throw CentralError.invalidAttribute(characteristic.uuid)
            }
        }
        // write
        await storage.updateState {
            $0.characteristicValues[characteristic] = data
        }
    }
    
    /// Discover descriptors
    public func discoverDescriptors(
        for characteristic: Characteristic<Peripheral, AttributeID>
    ) async throws -> [Descriptor<Peripheral, AttributeID>] {
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
        guard await storage.state.connected.contains(characteristic.peripheral) else {
            throw CentralError.disconnected
        }
        return await storage.state.descriptors[characteristic] ?? []
    }
    
    /// Read descriptor
    public func readValue(
        for descriptor: Descriptor<Peripheral, AttributeID>
    ) async throws -> Data {
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
        guard await storage.state.connected.contains(descriptor.peripheral) else {
            throw CentralError.disconnected
        }
        return await storage.state.descriptorValues[descriptor] ?? Data()
    }
    
    /// Write descriptor
    public func writeValue(
        _ data: Data,
        for descriptor: Descriptor<Peripheral, AttributeID>
    ) async throws {
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
        guard await storage.state.connected.contains(descriptor.peripheral) else {
            throw CentralError.disconnected
        }
        await storage.updateState {
            $0.descriptorValues[descriptor] = data
        }
    }
    
    public func notify(
        for characteristic: GATT.Characteristic<GATT.Peripheral, AttributeID>
    ) async throws -> AsyncCentralNotifications<MockCentral> {
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
        guard await storage.state.connected.contains(characteristic.peripheral) else {
            throw CentralError.disconnected
        }
        return AsyncCentralNotifications { [unowned self] continuation in
            if let notifications = await storage.state.notifications[characteristic] {
                for notification in notifications {
                    try await Task.sleep(nanoseconds: 100_000_000)
                    continuation(notification)
                }
            }
        }
    }
    
    /// Read MTU
    public func maximumTransmissionUnit(for peripheral: Peripheral) async throws -> MaximumTransmissionUnit {
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
        guard await storage.state.connected.contains(peripheral) else {
            throw CentralError.disconnected
        }
        return .default
    }
    
    // Read RSSI
    public func rssi(for peripheral: Peripheral) async throws -> RSSI {
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
        return .init(rawValue: 127)!
    }
}

// MARK: - Supporting Types

internal extension MockCentral {
    
    actor Storage {
        init() { }
        var bluetoothState: DarwinBluetoothState = .unknown
        
        func stateDidChange(_ newValue: DarwinBluetoothState) {
            bluetoothState = newValue
        }
        
        var state = State()
        
        func updateState<T>(_ block: (inout State) -> (T)) -> T {
            return block(&state)
        }
        
        var continuation = Continuation()
        
        func continuation(_ block: (inout Continuation) -> ()) {
            block(&continuation)
        }
    }
}

internal extension MockCentral {
    
    struct State {
        var isScanning = false
        var scanData: [MockScanData] = [.beacon, .smartThermostat, .lock, .lock(2), .lock(3)]
        var connected = Set<Peripheral>()
        var characteristics: [MockService: [MockCharacteristic]] = [
            .deviceInformation: [
                .deviceName,
                .manufacturerName,
                .modelNumber,
                .serialNumber
            ],
            .battery: [
                .batteryLevel
            ],
            .savantSystems: [
                .savantTest
            ],
            .lock(0x01): [
                .lockInformation(0x01)
            ],
            .lock(0x02): [
                .lockInformation(0x02)
            ],
            .lock(0x03): [
                .lockInformation(0x03)
            ]
        ]
        var descriptors: [MockCharacteristic: [MockDescriptor]] = [
            .batteryLevel: [.clientCharacteristicConfiguration(.beacon)],
            .savantTest: [.clientCharacteristicConfiguration(.smartThermostat)],
        ]
        var characteristicValues: [MockCharacteristic: Data] = [
            .deviceName: Data("iBeacon".utf8),
            .manufacturerName: Data("Apple Inc.".utf8),
            .modelNumber: Data("iPhone11.8".utf8),
            .serialNumber: Data(UUID().uuidString.utf8),
            .batteryLevel: Data([100]),
            .savantTest: Data(UUID().uuidString.utf8),
            .lockInformation(0x01): LockInformationCharacteristic(
                id: UUID(),
                buildVersion: .current,
                version: .current,
                status: .unlock,
                unlockActions: [.default]
            ).data,
            .lockInformation(0x02): LockInformationCharacteristic(
                id: UUID(),
                buildVersion: .current,
                version: .current,
                status: .unlock,
                unlockActions: [.default]
            ).data,
            .lockInformation(0x03): LockInformationCharacteristic(
                id: UUID(),
                buildVersion: .current,
                version: .current,
                status: .unlock,
                unlockActions: [.default]
            ).data
        ]
        var descriptorValues: [MockDescriptor: Data] = [
            .clientCharacteristicConfiguration(.beacon): Data([0x00]),
            .clientCharacteristicConfiguration(.smartThermostat): Data([0x00]),
        ]
        var notifications: [MockCharacteristic: [Data]] = [
            .batteryLevel: [
                Data([99]),
                Data([98]),
                Data([95]),
                Data([80]),
                Data([75]),
                Data([25]),
                Data([20]),
                Data([5]),
                Data([1]),
            ],
            .savantTest: [
                Data(UUID().uuidString.utf8),
                Data(UUID().uuidString.utf8),
                Data(UUID().uuidString.utf8),
                Data(UUID().uuidString.utf8),
            ]
        ]
    }
    
    struct Continuation {
        var scan: AsyncThrowingStream<ScanData<Peripheral, Advertisement>, Error>.Continuation?
        var isScanning: AsyncStream<Bool>.Continuation?
    }
}
#endif
