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
import CoreLock

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
            try? await Task.sleep(timeInterval: 0.01)
            return await storage.bluetoothState
        }
    }
    
    public var peripherals: Set<GATT.Peripheral> {
        get async {
            try? await Task.sleep(timeInterval: 0.01)
            return await Set(storage.state.scanData.map { $0.peripheral })
        }
    }
    
    private let storage = Storage()
    
    // MARK: - Initialization
    
    internal init() {
        Task {
            try await Task.sleep(timeInterval: 0.3)
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
            await self.storage.updateState {
                $0.isScanning = true
            }
            defer {
                Task {
                    await self.storage.updateState {
                        $0.isScanning = false
                    }
                }
            }
            try await Task.sleep(timeInterval: 0.2)
            var count = 0
            for scanData in await self.storage.state.scanData {
                // apply filter
                if services.isEmpty == false {
                    let foundServiceUUIDs = scanData.advertisementData.serviceUUIDs ?? []
                    guard Set(foundServiceUUIDs.filter({ services.contains($0) })) == services else {
                        continue
                    }
                }
                try await Task.sleep(timeInterval: 0.1)
                guard await self.storage.state.isScanning else {
                    continue
                }
                continuation(scanData)
                count += 1
            }
            self.log?("Discovered \(count) peripherals")
        }
    }
    
    /// Connect to the specified device
    public func connect(to peripheral: Peripheral) async throws {
        log?("Will connect to \(peripheral)")
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
                if $0.connected.remove(peripheral) != nil {
                    self.log?("Will disconnect \(peripheral)")
                }
            }
        }
    }
    
    /// Disconnect all connected devices.
    public func disconnectAll() {
        self.log?("Will disconnect all")
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
        log?("Peripheral \(peripheral) will discover services")
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
        log?("Peripheral \(service.peripheral) will discover included services of service \(service.uuid)")
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
        log?("Peripheral \(service.peripheral) will discover characteristics of service \(service.uuid)")
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
        log?("Peripheral \(characteristic.peripheral) will read characteristic \(characteristic.uuid)")
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
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
        log?("Peripheral \(characteristic.peripheral) will write characteristic \(characteristic.uuid)")
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
        // mock
        guard let (index, lock) = MockLock.locks
            .enumerated()
            .first(where: { Peripheral.lock(UInt8($0.offset)) == characteristic.peripheral })
            else { return }
        switch characteristic.uuid {
        case ListEventsCharacteristic.uuid:
            guard let listEventsCharacteristic = ListEventsCharacteristic(data: data) else {
                throw CentralError.invalidAttribute(ListEventsCharacteristic.uuid)
            }
            let key = listEventsCharacteristic.encryptedData.authentication.message.id
            guard let keyData = await Store.shared[key: key] else {
                throw CentralError.invalidAttribute(ListEventsCharacteristic.uuid)
            }
            let request = try listEventsCharacteristic.decrypt(using: keyData)
            let events = request.fetchRequest.map { lock.events.fetch($0) } ?? lock.events
            // build notifications
            let notifications = EventListNotification
                .from(list: events)
                .reduce([], { try! $0 + EventsCharacteristic.from($1, id: key, key: keyData, maximumUpdateValueLength: 20) })
                .map { $0.data }
            guard let continuation = await storage.state.notifications[.lockEventsNotifications(UInt8(index))] else {
                assertionFailure()
                return
            }
            notifications.forEach {
                continuation.yield($0)
            }
        case ListKeysCharacteristic.uuid:
            guard let listKeysCharacteristic = ListKeysCharacteristic(data: data) else {
                throw CentralError.invalidAttribute(ListKeysCharacteristic.uuid)
            }
            let key = listKeysCharacteristic.authentication.message.id
            guard let keyData = await Store.shared[key: key] else {
                throw CentralError.invalidAttribute(ListKeysCharacteristic.uuid)
            }
            let keysList = KeysList(
                keys: lock.keys,
                newKeys: lock.newKeys
            )
            let notifications = KeyListNotification
                .from(list: keysList)
                .reduce([], { try! $0 + KeysCharacteristic.from($1, id: key, key: keyData, maximumUpdateValueLength: 20) })
                .map { $0.data }
            guard let continuation = await storage.state.notifications[.lockKeysNotifications(UInt8(index))] else {
                assertionFailure()
                return
            }
            notifications.forEach {
                continuation.yield($0)
            }
        default:
            return
        }
    }
    
    /// Discover descriptors
    public func discoverDescriptors(
        for characteristic: Characteristic<Peripheral, AttributeID>
    ) async throws -> [Descriptor<Peripheral, AttributeID>] {
        log?("Peripheral \(characteristic.peripheral) will discover descriptors of characteristic \(characteristic.uuid)")
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
        log?("Peripheral \(descriptor.peripheral) will read descriptor \(descriptor.uuid)")
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
        log?("Peripheral \(descriptor.peripheral) will write descriptor \(descriptor.uuid)")
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
        log?("Peripheral \(characteristic.peripheral) will enable notifications for characteristic \(characteristic.uuid)")
        let state = await self.state
        guard state == .poweredOn else {
            throw DarwinCentralError.invalidState(state)
        }
        guard await storage.state.connected.contains(characteristic.peripheral) else {
            throw CentralError.disconnected
        }
        return AsyncCentralNotifications(bufferSize: 1000, onTermination: {
            Task {
                await self.storage.updateState {
                    $0.notifications[characteristic] = nil
                }
            }
        }) { continuation in
            Task {
                await self.storage.updateState {
                    $0.notifications[characteristic] = continuation
                }
            }
        }
    }
    
    /// Read MTU
    public func maximumTransmissionUnit(for peripheral: Peripheral) async throws -> MaximumTransmissionUnit {
        self.log?("Will read MTU for \(peripheral)")
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
        log?("Will read RSSI for \(peripheral)")
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
        var scanData: [MockScanData] = [.beacon, .smartThermostat] + MockLock.locks.enumerated().map { .lock(UInt8($0.offset)) }
        var connected = Set<Peripheral>()
        var characteristics: [MockService: [MockCharacteristic]] = {
            let characteristics = MockLock.locks.enumerated().map { (index, lock) in
                let id = UInt8(index)
                return (MockService.lock(id), [
                    MockCharacteristic.lockInformation(id),
                    MockCharacteristic.unlock(id),
                    MockCharacteristic.lockEventsRequest(id),
                    MockCharacteristic.lockEventsNotifications(id),
                    MockCharacteristic.lockKeysRequest(id),
                    MockCharacteristic.lockKeysNotifications(id)
                ])
            }
            return .init(uniqueKeysWithValues: characteristics)
        }()
        var descriptors: [MockCharacteristic: [MockDescriptor]] = [
            .batteryLevel: [.clientCharacteristicConfiguration(.beacon)],
            .savantTest: [.clientCharacteristicConfiguration(.smartThermostat)],
        ]
        var characteristicValues: [MockCharacteristic: Data] = {
            var values = [MockCharacteristic: Data]()
            for (index, lock) in MockLock.locks.enumerated() {
                values[.lockInformation(UInt8(index))] = LockInformationCharacteristic(
                    id: lock.id,
                    buildVersion: .current,
                    version: .current,
                    status: lock.status,
                    unlockActions: [.default]
                ).data
                values[.unlock(UInt8(index))] = Data()
                values[.lockEventsRequest(UInt8(index))] = Data()
                values[.lockKeysRequest(UInt8(index))] = Data()
            }
            return values
        }()
            //.init(uniqueKeysWithValues: MockLock.locks.enumerated().reduce([(MockCharacteristic, Data)](), { (index, lock) in
        var descriptorValues: [MockDescriptor: Data] = [
            .clientCharacteristicConfiguration(.beacon): Data([0x00]),
            .clientCharacteristicConfiguration(.smartThermostat): Data([0x00]),
        ]
        var notifications = [MockCharacteristic: AsyncIndefiniteStream<Data>.Continuation]()
    }
    
    struct Continuation {
        var scan: AsyncThrowingStream<ScanData<Peripheral, Advertisement>, Error>.Continuation?
        var isScanning: AsyncStream<Bool>.Continuation?
    }
}
#endif
