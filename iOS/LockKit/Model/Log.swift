//
//  Log.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation

public func log(_ text: String) {
    
    // only print for debug builds
    #if DEBUG
    print(text)
    #endif
    
    do { try Log.shared.log(text) }
    catch { assertionFailure("Could not write log: \(error)"); return }
}

public extension Log {
    
    static var shared: Log = .appCache
    
    static let appCache: Log = try! Store.caches.create(date: Date(), bundle: .main)
}

public struct Log {
    
    public static let fileExtension = "log"
    
    public let url: URL
    
    public init?(url: URL) {
        
        guard url.isFileURL,
            url.pathExtension.lowercased() == Log.fileExtension
            else { return nil }
        
        self.url = url
    }
    
    fileprivate init(unsafe url: URL) {
        
        assert(Log(url: url) != nil, "Invalid url \(url)")
        
        self.url = url
    }
    
    public func load() throws -> String {
        
        return try String(contentsOf: url)
    }
    
    public func log(_ text: String) throws {
        
        let newLine = "\n" + text
        
        let data = Data(newLine.utf8)
        
        try data.append(fileURL: url)
    }
}

private extension Data {
    
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}

// MARK: - Log Store

public extension Log {
    
    final class Store {
        
        public typealias Item = Log
        
        public static let caches: Log.Store = Store(directory: .cachesDirectory, subfolder: "logs")!
        
        public static let documents: Log.Store = Store(directory: .documentDirectory, subfolder: "logs")!
        
        public let folder: URL
        
        public private(set) var items = [Item]()
        
        private init(folder: URL) {
            
            self.folder = folder
            try! self.load()
        }
        
        private convenience init?(directory: FileManager.SearchPathDirectory, subfolder: String? = nil) {
            
            guard let path = NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true).first
                else { return nil }
            
            var url = URL(fileURLWithPath: path)
            
            if let subfolder = subfolder {
                
                url.appendPathComponent(subfolder)
                
                var isDirectory: ObjCBool = false
                
                FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                
                if isDirectory.boolValue == false {
                    
                    do { try FileManager.default.createDirectory(at: url,
                                                                 withIntermediateDirectories: true,
                                                                 attributes: nil) }
                        
                    catch { return nil }
                }
            }
            
            self.init(folder: url)
        }
        
        public func load() throws {
            
            let files = try FileManager.default.contentsOfDirectory(at: folder,
                                                                    includingPropertiesForKeys: nil,
                                                                    options: .skipsSubdirectoryDescendants)
            
            self.items = files
                .compactMap { Item(url: $0) }
                .sorted(by: { $0.url.lastPathComponent > $1.url.lastPathComponent })
        }
        
        private func item(named name: String) -> Item {
            
            let filename = name + "." + Item.fileExtension
            let url = folder.appendingPathComponent(filename)
            let item = Item(unsafe: url)
            return item
        }
        
        @discardableResult
        public func create(_ name: String) throws -> Log {
            
            let item = self.item(named: name)
            return item
        }
        
        @discardableResult
        public func create(date: Date = Date(), bundle: Bundle = .main) throws -> Log {
            
            let name = "\(bundle.bundleIdentifier ?? bundle.bundleURL.lastPathComponent) \(Int(date.timeIntervalSince1970))"
            return try create(name)
        }
    }
}
