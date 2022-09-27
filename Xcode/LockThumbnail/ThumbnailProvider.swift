//
//  ThumbnailProvider.swift
//  LockThumbnail
//
//  Created by Alsey Coleman Miller on 9/27/22.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI
import QuickLookThumbnailing
import LockKit

final class ThumbnailProvider: QLThumbnailProvider {
    
    static let initialize: Void = {
        //Log.shared = .thumbnail
        log("🖼 Loading \(ThumbnailProvider.self)")
    }()
    
    override func provideThumbnail(for request: QLFileThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        _ = type(of: self).initialize
        
        log("🖼 Render thumbnail for eKey file \(request.fileURL)")
        
        #if DEBUG
        print("""
            Maximum size: \(request.maximumSize)
            Minimum size: \(request.minimumSize)
            Scale: \(request.scale)
            """)
        #endif
        
        Task(priority: .userInitiated) {
            do {
                let reply = try await provideThumbnail(for: request)
                handler(reply, nil)
            } catch {
                handler(nil, error)
            }
        }
    }
    
    private func provideThumbnail(for request: QLFileThumbnailRequest) async throws -> QLThumbnailReply {
        
        let permission: Permission
        let decoder = JSONDecoder()
        
        do {
            let data = try Data(contentsOf: request.fileURL),
            invitation = try decoder.decode(NewKey.Invitation.self, from: data)
            permission = invitation.key.permission
        } catch {
            log("⚠️ Unable to load eKey file \(request.fileURL). \(error)")
            permission = .admin
        }
        
        let contextWidth = min(
            request.maximumSize.width,
            request.maximumSize.height
        )
        
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
        
        return QLThumbnailReply(contextSize: contextSize, currentContextDrawing: {
            
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
        })
    }
}
