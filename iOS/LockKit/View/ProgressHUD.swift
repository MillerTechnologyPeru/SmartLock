//
//  ProgressHUD.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/24/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import JGProgressHUD

public extension JGProgressHUD {
    
    static func currentStyle(for viewController: UIViewController) -> JGProgressHUD {
        if #available(iOS 12.0, iOSApplicationExtension 12.0, *) {
            return JGProgressHUD(userInterfaceStyle: viewController.traitCollection.userInterfaceStyle)
        } else {
            return JGProgressHUD(style: .dark) // default for light environment
        }
    }
    
    @available(iOS 12.0, iOSApplicationExtension 12.0, *)
    convenience init(userInterfaceStyle style: UIUserInterfaceStyle) {
        self.init(style: .init(userInterfaceStyle: style))
    }
}

public extension JGProgressHUDStyle {
    
    @available(iOS 12.0, iOSApplicationExtension 12.0, *)
    init(userInterfaceStyle: UIUserInterfaceStyle) {
        
        switch userInterfaceStyle {
        case .light:
            self = .dark
        case .dark:
            self = .light
        case .unspecified:
            self = .dark
        @unknown default:
            self = .dark
        }
    }
}
