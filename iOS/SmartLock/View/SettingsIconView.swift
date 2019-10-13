//
//  SettingsIconView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import LockKit

@IBDesignable
public final class SettingsIconView: UIView {
    
    // MARK: - Properties
    
    public var icon: Icon = .report {
        didSet { setNeedsDisplay() }
    }
    
    // MARK: - Methods
    
    public override func draw(_ rect: CGRect) {
        
        switch icon {
        case .report:
            StyleKit.drawSettingsReportIcon(frame: bounds, resizing: .aspectFit)
        case .logs:
            StyleKit.drawSettingsLogsIcon(frame: bounds, resizing: .aspectFit)
        case .bluetooth:
            StyleKit.drawSettingsBluetoothIcon(frame: bounds, resizing: .aspectFit)
        case .cloud:
            StyleKit.drawSettingsCloudIcon(frame: bounds, resizing: .aspectFit)
        }
    }
}

// MARK: - IB Support

public extension SettingsIconView {
    
    @IBInspectable
    var iconName: String {
        get { return icon.rawValue }
        set { if let icon = Icon(rawValue: newValue) { self.icon = icon } }
    }
}

// MARK: - Supporting Types

public extension SettingsIconView {
    
    enum Icon: String {
        
        case report
        case logs
        case bluetooth
        case cloud
    }
}
