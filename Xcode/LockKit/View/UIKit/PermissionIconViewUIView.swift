//
//  PermissionIconViewUIView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

#if os(iOS) || os(tvOS)
import Foundation
import UIKit
import SwiftUI
import CoreLock

extension PermissionIconView: UIViewRepresentable {
    
    public func makeUIView(context: Context) -> UIViewType {
        return UIViewType(permission: permission)
    }
    
    public func updateUIView(_ view: UIViewType, context: Context) {
        view.permission = permission
    }
}

public extension PermissionIconView {
    
    @objc(LockPermissionIconView)
    @IBDesignable
    final class UIViewType: UIView {
        
        // MARK: - Properties
        
        public var permission: PermissionType = .admin {
            didSet { setNeedsDisplay() }
        }
        
        // MARK: - Initialization
        
        public init(
            permission: PermissionType,
            frame: CGRect = CGRect(origin: .zero, size: CGSize(width: 48, height: 48))
        ) {
            self.permission = permission
            super.init(frame: frame)
            self.backgroundColor = .clear
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        public override func awakeFromNib() {
            super.awakeFromNib()
            self.backgroundColor = .clear
        }
        
        // MARK: - Methods
        
        public override func draw(_ rect: CGRect) {
            
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

// MARK: - IB Support

public extension PermissionIconView.UIViewType {
    
    @IBInspectable
    var permissionName: String {
        get { return PermissionName(permission).rawValue }
        set { if let name = PermissionName(rawValue: newValue) { self.permission = name.permission } }
    }
}

// MARK: - Image Rendering

public extension UIImage {
    
    static func permissionType(_ permissionType: PermissionType, size: CGSize = CGSize(width: 32, height: 32)) -> UIImage {
        let view = PermissionIconView.UIViewType(permission: permissionType, frame: CGRect(origin: .zero, size: size))
        let renderer = UIGraphicsImageRenderer(size: view.bounds.size)
        let image = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        return image
    }
}
 
// MARK: - Supporting Types

private extension PermissionIconView.UIViewType {
    
    enum PermissionName: String {
        
        case owner
        case admin
        case anytime
        case scheduled
        
        init(_ permission: PermissionType) {
            self = unsafeBitCast(permission, to: PermissionName.self)
        }
        
        var permission: PermissionType {
            return unsafeBitCast(self, to: PermissionType.self)
        }
    }
}
#endif
