//
//  PermissionIconView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/23/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreLock

@IBDesignable
public final class PermissionIconView: UIView {
    
    // MARK: - Properties
    
    public var permission: PermissionType = .admin {
        didSet { setNeedsDisplay() }
    }
    
    // MARK: - Initialization
    
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

// MARK: - IB Support

public extension PermissionIconView {
    
    @IBInspectable
    var permissionName: String {
        get { return PermissionName(permission).rawValue }
        set { if let name = PermissionName(rawValue: newValue) { self.permission = name.permission } }
    }
}

// MARK: - Supporting Types

private extension PermissionIconView {
    
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
