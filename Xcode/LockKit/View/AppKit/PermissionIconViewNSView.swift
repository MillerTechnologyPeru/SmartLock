//
//  PermissionIconViewNSView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

#if canImport(AppKit)
import Foundation
import SwiftUI
import CoreLock
import AppKit

extension PermissionIconView: NSViewRepresentable {
    
    public func makeNSView(context: Context) -> NSViewType {
        return NSViewType(permission: permission)
    }
    
    public func updateNSView(_ view: NSViewType, context: Context) {
        view.permission = permission
    }
}

public extension PermissionIconView {
    
    @objc(LockPermissionIconView)
    final class NSViewType: NSView {
        
        // MARK: - Properties
        
        public var permission: PermissionType = .admin {
            didSet { setNeedsDisplay(bounds) }
        }
        
        // MARK: - Initialization
        
        public init(
            permission: PermissionType,
            frame: CGRect = CGRect(origin: .zero, size: CGSize(width: 48, height: 48))
        ) {
            self.permission = permission
            super.init(frame: frame)
            //self.backgroundColor = .clear
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        public override func awakeFromNib() {
            super.awakeFromNib()
            //self.backgroundColor = .clear
        }
        
        // MARK: - Methods
        
        public override func draw(_ rect: NSRect) {
            
            switch permission {
            case .owner:
                StyleKit.drawPermissionBadgeOwner(frame: bounds)
            case .admin:
                StyleKit.drawPermissionBadgeAdmin(frame: bounds)
            case .anytime:
                StyleKit.drawPermissionBadgeAnytime(frame: bounds)
            case .scheduled:
                StyleKit.drawPermissionBadgeScheduled(frame: bounds)
            }
        }
    }
}

#endif
