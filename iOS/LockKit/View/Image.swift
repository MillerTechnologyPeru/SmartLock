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
    
    convenience init?(lockKit name: String) {
        self.init(named: name, in: .lockKit, compatibleWith: nil)
    }
}

/// Get URL from asset.
public final class AssetExtractor {
    
    public static let shared = AssetExtractor()
    
    private init() { }
    
    private lazy var fileManager = FileManager()
    
    private lazy var cacheDirectory = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    
    public func url(for imageName: String, in bundle: Bundle) -> URL? {
        
        let fileName = bundle.bundleIdentifier ?? bundle.bundleURL.lastPathComponent + "." + imageName + ".png"
        let url = cacheDirectory.appendingPathComponent(fileName)
        
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
