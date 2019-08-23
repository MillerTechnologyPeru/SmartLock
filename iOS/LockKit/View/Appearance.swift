//
//  Appearance.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    
    /// Configure the application's UI appearance
    static func configureLockAppearance() {
        
        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().prefersLargeTitles = true
            UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        }
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().barTintColor = StyleKit.wirelessBlue
        UITabBar.appearance().tintColor = StyleKit.wirelessBlue
    }
}
