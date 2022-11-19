//
//  SetupCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import Bluetooth
import GATT

/// Used for initial lock setup.
public struct SetupCharacteristic: TLVEncryptedCharacteristic, Codable, Equatable {
    
    public static var uuid: BluetoothUUID { BluetoothUUID(rawValue: "129E401C-044D-11E6-8FA9-09AB70D5A8C7")! }
    
    public static var service: GATTProfileService.Type { LockService.self }
    
    public static var properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> { [.write] }
    
    public let encryptedData: EncryptedData
    
    public init(encryptedData: EncryptedData) {
        self.encryptedData = encryptedData
    }
    
    public init(request: SetupRequest, sharedSecret: KeyData) throws {
        
        let requestData = try type(of: self).encoder.encode(request)
        self.encryptedData = try EncryptedData(encrypt: requestData, using: sharedSecret, id: .zero)
    }
    
    public func decrypt(using sharedSecret: KeyData) throws -> SetupRequest {
        
        let data = try encryptedData.decrypt(using: sharedSecret)
        guard let value = try? type(of: self).decoder.decode(SetupRequest.self, from: data)
            else { throw GATTError.invalidData(data) }
        return value
    }
}

// MARK: - Supporting Types

public struct SetupRequest: Equatable, Codable {
    
    /// Key identifier
    public let id: UUID
    
    /// Key secret
    public let secret: KeyData
    
    public init(id: UUID = UUID(),
                secret: KeyData = KeyData()) {
        
        self.id = id
        self.secret = secret
    }
}

public extension Key {
    
    /// Initialize a new owner key from a setup request. 
    init(setup: SetupRequest) {
        
        self.init(
            id: setup.id,
            name: "Owner",
            created: Date(),
            permission: .owner
        )
    }
}

// MARK: - Central

public extension CentralManager {
    
    /// Setup lock.
    @discardableResult
    func setup(
        _ request: SetupRequest,
        using sharedSecret: KeyData,
        for peripheral: Peripheral
    ) async throws -> LockInformation {
        try await connection(for: peripheral) {
            // write setup request
            try await $0.setup(request, using: sharedSecret)
            // validate status
            let information = try await $0.readInformation()
            guard information.status != .setup else {
                throw GATTError.invalidData(nil)
            }
            return information
        }
    }
}

public extension GATTConnection {
    
    /// Setup lock.
    func setup(
        _ request: SetupRequest,
        using sharedSecret: KeyData
    ) async throws {
        // encrypt owner key data
        let characteristicValue = try SetupCharacteristic(
            request: request,
            sharedSecret: sharedSecret
        )
        // write setup characteristic
        try await write(characteristicValue)
    }
}
