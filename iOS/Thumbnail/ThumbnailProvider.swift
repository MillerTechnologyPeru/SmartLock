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
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        let permission: Permission
        
        let decoder = JSONDecoder()
        
        // load eKey file
        do {
            let data = try Data(contentsOf: request.fileURL),
            invitation = try decoder.decode(NewKey.Invitation.self, from: data)
            permission = invitation.key.permission
        } catch {
            log("Unable to load eKey file. \(error)")
            permission = .admin
        }
        
        // There are three ways to provide a thumbnail through a QLThumbnailReply. Only one of them should be used.
        
        // First way: Draw the thumbnail into the current context, set up with UIKit's coordinate system.
        
        let contextSize = request.maximumSize
        handler(QLThumbnailReply(contextSize: contextSize, currentContextDrawing: { () -> Bool in
            
            // Draw the thumbnail here.
            let width = min(request.maximumSize.width, request.maximumSize.height) * 0.8
            let frame = CGRect(
                origin: .zero,
                size: CGSize(
                    width: width,
                    height: width
                )
            )
            
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
        
        /*
        
        // Second way: Draw the thumbnail into a context passed to your block, set up with Core Graphics's coordinate system.
        handler(QLThumbnailReply(contextSize: request.maximumSize, drawing: { (context) -> Bool in
            // Draw the thumbnail here.
         
            // Return true if the thumbnail was successfully drawn inside this block.
            return true
        }), nil)
         
        // Third way: Set an image file URL.
        handler(QLThumbnailReply(imageFileURL: Bundle.main.url(forResource: "fileThumbnail", withExtension: "jpg")!), nil)
        
        */
    }
}
