//
//  AssetExtractor.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/23/22.
//

#if canImport(UIKit)
import Foundation
import UIKit

/// Get URL from asset.
@available(iOS 8.0, watchOS 6.0, *)
public final class AssetExtractor {
    
    public static let shared = AssetExtractor()
    
    private init() { }
    
    private lazy var fileManager = FileManager()
    
    private lazy var cachesDirectory: URL = {
        guard let url = fileManager.cachesDirectory
            else { fatalError("Could not load cache directory") }
        return url
    }()
    
    @available(iOS 8.0, watchOS 6.0, *)
    public func url(for imageName: String, in bundle: Bundle = .lockKit) -> URL? {
        
        let fileName = (bundle.bundleIdentifier ?? bundle.bundleURL.lastPathComponent) + "." + imageName + ".png"
        let url = cachesDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: url.path) == false {
            guard let image = UIImage(named: imageName, in: bundle, compatibleWith: nil)
                else { return nil }
            guard let imageData = image.pngData()
                else { fatalError("Could not convert image to PNG") }
            fileManager.createFile(atPath: url.path, contents: imageData, attributes: nil)
        }
        
        return url
    }
}
#endif
