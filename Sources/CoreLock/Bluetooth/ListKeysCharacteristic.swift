//
//  ListKeysCharacteristic.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 6/29/19.
//

import Foundation
import Bluetooth
import GATT

/// List keys request
public struct ListKeysCharacteristic: TLVCharacteristic, Codable, Equatable {
    
    public static let uuid = BluetoothUUID(rawValue: "35233251-5733-48DD-A8CE-0C2B3B4B6949")!
    
    public static let service: GATTProfileService.Type = LockService.self
    
    public static let properties: Bluetooth.BitMaskOptionSet<GATT.Characteristic.Property> = [.write]
    
    /// HMAC of key and nonce, and HMAC message
    public let authentication: Authentication
    
    public init(authentication: Authentication) {
        self.authentication = authentication
    }
}

// MARK: - Central
/*
public extension CentralManager {
    
    /// Retreive a list of all keys on device.
    func listKeys(
        using key: KeyCredentials,
        for peripheral: Peripheral,
        notification: ((KeyListNotification) -> ())? = nil,
        log: ((String) -> ())? = nil
    ) async throws {
        try await connect(to: peripheral) {
            let stream = try await $0.listKeys(using: key, log: log)
            //var list = KeysList()
            for try await value in stream {
                notification?(value)
                //list.append(value.key)
            }
            //return list
        }
    }
}
*/
public extension GATTConnection {
    
    /// Retreive a list of all keys on device.
    func listKeys(
        using key: KeyCredentials,
        log: ((String) -> ())? = nil
    ) async throws -> AsyncThrowingStream<KeyListNotification, Error> {
        let write = {
            ListKeysCharacteristic(
                authentication: Authentication(
                    key: key.secret,
                    message: AuthenticationMessage(
                        digest: Digest(hash: Data()),
                        id: key.id
                    )
                )
            )
        }
        return try await list(write(), KeysCharacteristic.self, key: key, log: log)
    }
}
