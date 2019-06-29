//
//  File.swift
//  lockd
//
//  Created by Alsey Coleman Miller on 6/27/19.
//

import Foundation

public final class JSONFile <T: Codable> {
    
    // MARK: - Properties
    
    /// File URL
    public let url: URL
    
    /// Codable value
    public private(set) var value: T
    
    private let fileManager = FileManager()
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // MARK: - Initialization
    
    public init(url: URL,
                decoder: JSONDecoder = JSONDecoder(),
                encoder: JSONEncoder = JSONEncoder()) throws {
        
        // attempt to load previous value.
        self.value = try decoder.decode(T.self, from: url)
        self.url = url
        self.decoder = decoder
        self.encoder = encoder
    }
    
    public init(url: URL,
                defaultValue: T,
                decoder: JSONDecoder = JSONDecoder(),
                encoder: JSONEncoder = JSONEncoder()) throws {
        
        // attempt to load previous value.
        self.value = (try? decoder.decode(T.self, from: url)) ?? defaultValue
        self.url = url
        self.decoder = decoder
        self.encoder = encoder
        try write(value) // write file
    }
    
    // MARK: - Methods
    
    public func write(_ newValue: T) throws {
        
        let data = try encoder.encode(newValue)
        
        if fileManager.fileExists(atPath: url.path) {
            try data.write(to: url, options: .atomic)
        } else {
            try fileManager.createIntermediateDirectories(for: url)
            guard fileManager.createFile(atPath: url.path, contents: data, attributes: nil) else {
                throw CocoaError(.fileWriteUnknown)
            }
        }
        self.value = newValue
    }
}

internal extension FileManager {
    
    func createIntermediateDirectories(for url: URL) throws {
        
        guard url.pathComponents.count > 1 else { return }
        
        var pathComponents = url.pathComponents
        pathComponents.removeLast()
        let directoryPath = pathComponents.reduce("", { $0 + ($0.isEmpty ? "" : "/") + $1 })
        try createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
    }
}
