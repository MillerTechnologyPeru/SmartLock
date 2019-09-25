//
//  ThumbnailProvider.swift
//  Thumbnail
//
//  Created by Alsey Coleman Miller on 9/24/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import QuickLookThumbnailing
import CoreLock
import LockKit

final class ThumbnailProvider: QLThumbnailProvider {
    
    static let initialize: Void = {
        Log.shared = .thumbnailProvider
        log("🖼 Loading \(ThumbnailProvider.self)")
    }()
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        _ = type(of: self).initialize
        
        log("🖼 Render thumbnail for eKey file \(request.fileURL.path)")
        
        #if DEBUG
        log("""
            Maximum size: \(request.maximumSize)
            Minimum size: \(request.minimumSize)
            Scale: \(request.scale)
            """)
        #endif
        
        let permission: Permission
        let decoder = JSONDecoder()
        
        // load eKey file
        do {
            let data = try Data(contentsOf: request.fileURL),
            invitation = try decoder.decode(NewKey.Invitation.self, from: data)
            permission = invitation.key.permission
        } catch {
            log("⚠️ Unable to load eKey file \(request.fileURL.path). \(error)")
            permission = .admin
        }
        
        let contextWidth = min(
            request.maximumSize.width,
            request.maximumSize.height
            )
        //contextWidth *= request.scale
        
        let contextSize = CGSize(
            width: contextWidth,
            height: contextWidth
        )
        
        let imageWidth = contextWidth * 0.8
        
        let frame = CGRect(
            x: (contextWidth - imageWidth) / 2,
            y: (contextWidth - imageWidth) / 2,
            width: imageWidth,
            height: imageWidth
        )
        
        log("🖼 Will render \(permission) thumbail \(frame) in \(contextSize)")
        
        DispatchQueue.main.async {
            handler(QLThumbnailReply(contextSize: contextSize, currentContextDrawing: { () -> Bool in
                
                switch permission {
                case .owner:
                    StyleKit.drawPermissionBadgeOwner(frame: frame)
                case .admin:
                    StyleKit.drawPermissionBadgeAdmin(frame: frame)
                case .anytime:
                    StyleKit.drawPermissionBadgeAnytime(frame: frame)
                case .scheduled:
                    StyleKit.drawPermissionBadgeScheduled(frame: frame)
                }
                
                return true
            }), nil)
        }
    }
}

// MARK: - Logging

extension Log {
    
    static var thumbnailProvider: Log {
        struct Cache {
            static let log: Log = {
                do { return try Log.Store.lockAppGroup.create(date: Date(), bundle: .init(for: ThumbnailProvider.self)) }
                catch { assertionFailure("Could not create log file: \(error)"); return .appCache }
            }()
        }
        return Cache.log
    }
}
