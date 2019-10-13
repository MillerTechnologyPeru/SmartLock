//
//  Image.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

public extension UIImage {
    
    @available(iOS 8.0, watchOS 6.0, *)
    convenience init?(lockKit name: String) {
        self.init(named: name, in: .lockKit, compatibleWith: nil)
    }
}

#if os(watchOS)
public extension UIImage {
    
    @available(watchOS 6.0, *)
    convenience init?(named name: String, in bundle: Bundle, compatibleWith traits: UIImage.Configuration? = nil) {
        self.init(named: name, in: bundle, with: traits)
    }
}
#endif

#if os(iOS)
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
    public func url(for imageName: String, in bundle: Bundle) -> URL? {
        
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

import Rswift

public extension AssetExtractor {
    
    func url(for image: ImageResource) -> URL? {
        return url(for: image.name, in: image.bundle)
    }
}
#endif
