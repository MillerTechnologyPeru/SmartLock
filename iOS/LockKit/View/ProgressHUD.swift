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
        return JGProgressHUD(userInterfaceStyle: viewController.traitCollection.userInterfaceStyle)
    }
    
    convenience init(userInterfaceStyle style: UIUserInterfaceStyle) {
        self.init(style: .init(userInterfaceStyle: style))
    }
}

public extension JGProgressHUDStyle {
    
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
