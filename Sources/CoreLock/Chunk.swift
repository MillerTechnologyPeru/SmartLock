//
//  Chunk.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import TLVCoding

/// Chunk of data to send over BLE.
public struct Chunk: Equatable {
    
    /// The minimum length of bytes in this PDU.
    internal static let headerLength = MemoryLayout<UInt8>.size + MemoryLayout<UInt32>.size
    
    /// The bytes in this chunk
    public let isFirst: Bool
    
    /// The total amount of bytes.
    public let total: UInt32
    
    /// The bytes in this chunk
    public let bytes: Data
}

public extension Chunk {
    
    /// Prepare data to send in chunks that can be sent via notifications.
    static func from(_ data: Data, maximumUpdateValueLength: Int) -> [Chunk] {
        
        let chunkSize = maximumUpdateValueLength - headerLength
        
        let totalBytes = UInt32(data.count)
        
        return stride(from: 0, to: data.count, by: chunkSize)
            .lazy
            .map { Data(data[$0 ..< min($0 + chunkSize, data.count)]) }
            .enumerated()
            .map { Chunk(isFirst: $0.offset == 0, total: totalBytes, bytes: $0.element) }
    }
}

public extension Data {
    
    init(chunks: [Chunk]) {
        
        self = chunks.reduce(into: Data(capacity: chunks.length), { $0.append($1.bytes) })
    }
}

public extension Array where Iterator.Element == Chunk {
    
    var length: Int {
        
        return reduce(0, { $0 + $1.bytes.count })
    }
    
    var isComplete: Bool {
        
        guard let lastChunk = self.last
            else { return false }
        
        return Int(lastChunk.total) == self.length
    }
}

public extension Chunk {
    
    init?(data: Data) {
        
        guard data.count >= type(of: self).headerLength
            else { return nil }
        
        guard let isFirst = Bool(byteValue: data[0])
            else { return nil }
        
        self.isFirst = isFirst
        self.total = UInt32(littleEndian: UInt32(bytes: (data[1], data[2], data[3], data[4])))
        self.bytes = Data(data.dropFirst(type(of: self).headerLength)) // excluding initial bytes
    }
    
    var data: Data {
        
        let totalBytes = total.littleEndian.bytes
        
        return [isFirst.byteValue,
                totalBytes.0,
                totalBytes.1,
                totalBytes.2,
                totalBytes.3] + bytes
    }
}
