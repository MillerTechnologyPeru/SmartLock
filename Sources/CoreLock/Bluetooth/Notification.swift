//
//  Notification.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 9/1/19.
//

import Foundation
import Bluetooth
import GATT

public protocol GATTEncryptedNotification: GATTProfileCharacteristic {
    
    associatedtype Notification: GATTEncryptedNotificationValue
    
    var chunk: Chunk { get }
    
    init(chunk: Chunk)
    
    static func from(chunks: [Chunk]) throws -> EncryptedData
    
    static func from(chunks: [Chunk], using key: KeyData) throws -> Notification
    
    static func from(_ value: EncryptedData, maximumUpdateValueLength: Int) throws -> [Self]
    
    static func from(_ value: Notification, id: UUID, key: KeyData, maximumUpdateValueLength: Int) throws -> [Self]
}

public protocol GATTEncryptedNotificationValue {
    
    var isLast: Bool { get }
}

public extension GATTEncryptedNotification {
    
    init?(data: Data) {
        guard let chunk = Chunk(data: data)
            else { return nil }
        
        self.init(chunk: chunk)
    }
    
    var data: Data {
        return chunk.data
    }
}

internal extension GATTConnection {
    
    func list<Write, ChunkNotification>(
        _ write: @autoclosure () throws -> (Write),
        _ notify: ChunkNotification.Type,
        key: KeyCredentials,
        log: ((String) -> ())? = nil
    ) async throws -> AsyncThrowingStream<ChunkNotification.Notification, Error> where Write: GATTProfileCharacteristic, ChunkNotification: GATTEncryptedNotification {
        let stream = try await self.notify(ChunkNotification.self)
        let writeValue = try write()
        try await self.write(writeValue)
        return AsyncThrowingStream(ChunkNotification.Notification.self, bufferingPolicy: .unbounded) { continuation in
            Task.detached {
                do {
                    var chunks = [Chunk]()
                    chunks.reserveCapacity(2)
                    for try await chunkNotification in stream {
                        let chunk = chunkNotification.chunk
                        log?("Received chunk \(chunks.count + 1) (\(chunk.bytes.count) bytes)")
                        chunks.append(chunk)
                        assert(chunks.isEmpty == false)
                        guard chunks.length >= chunk.total else {
                            continue // wait for more chunks
                        }
                        let notificationValue = try ChunkNotification.from(chunks: chunks, using: key.secret)
                        chunks.removeAll(keepingCapacity: true)
                        continuation.yield(notificationValue)
                        guard notificationValue.isLast else {
                            continue // wait for final value
                        }
                        stream.stop()
                    }
                    continuation.finish()
                } catch {
                    stream.stop()
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
