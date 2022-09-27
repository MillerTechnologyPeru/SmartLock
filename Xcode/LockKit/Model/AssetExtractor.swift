//
//  AssetExtractor.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/23/22.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI

/// Get URL from asset.
@MainActor
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
    
    public func url(for imageName: String, in bundle: Bundle = .lockKit) -> URL? {
        
        let fileName = (bundle.bundleIdentifier ?? bundle.bundleURL.lastPathComponent) + "." + imageName + ".png"
        let url = cachesDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: url.path) == false {
            #if canImport(UIKit)
            guard let image = UIImage(named: imageName, in: bundle, compatibleWith: nil),
                  let imageData = image.pngData()
                else { return nil }
            #elseif canImport(AppKit)
            let image = Image(imageName, bundle: bundle)
            let imageRenderer = ImageRenderer(content: image)
            guard let imageData = imageRenderer.cgImage
                .map({ NSBitmapImageRep(cgImage: $0) })?
                .representation(using: .png, properties: [:])
                else { return nil }
            #endif
            fileManager.createFile(atPath: url.path, contents: imageData, attributes: nil)
        }
        
        return url
    }
}
