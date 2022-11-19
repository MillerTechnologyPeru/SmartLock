//
//  SettingsIconView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

#if os(iOS)
import Foundation
import UIKit
import SwiftUI
import LockKit

public struct SettingsIconView: UIViewRepresentable {
    
    // MARK: - Properties
    
    @State
    public var icon: SettingsIcon = .report
    
    // MARK: - Methods
    
    public func makeUIView(context: Context) -> UIViewType {
        let view = UIViewType(frame: CGRect(x: 0, y: 0, width: 32, height: 32))
        view.backgroundColor = .clear
        view.icon = self.icon
        return view
    }
    
    public func updateUIView(_ view: UIViewType, context: Context) {
        view.icon = self.icon
    }
}

// MARK: - UIView

public extension SettingsIconView {
    
    @objc(SettingsIconView)
    @IBDesignable
    final class UIViewType: UIView {
        
        // MARK: Properties
        
        public var icon: SettingsIcon = .report {
            didSet { setNeedsDisplay() }
        }
        
        public override var intrinsicContentSize: CGSize {
            frame.size
        }
        
        // MARK: Methods
        
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
}

// MARK: - IB Support

public extension SettingsIconView.UIViewType {
    
    @IBInspectable
    var iconName: String {
        get { return icon.rawValue }
        set { if let icon = SettingsIcon(rawValue: newValue) { self.icon = icon } }
    }
}

// MARK: - Supporting Types

/// Settings Icon
public enum SettingsIcon: String {
    
    case report
    case logs
    case bluetooth
    case cloud
}

#endif
