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
        
        UINavigationBar.appearance().configureLockAppearance()
        UITabBar.appearance().configureLockAppearance()
    }
}

internal extension UINavigationBar {
    
    func configureLockAppearance() {
        
        let barTintColor = StyleKit.wirelessBlue
        let tintColor: UIColor = .white
        let titleTextAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: UIColor.white
        ]
        
        if #available(iOSApplicationExtension 11.0, *) {
            self.largeTitleTextAttributes = titleTextAttributes
        }
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = barTintColor
            appearance.titleTextAttributes = titleTextAttributes
            appearance.largeTitleTextAttributes = titleTextAttributes
            self.standardAppearance = appearance
            self.compactAppearance = appearance
            self.scrollEdgeAppearance = appearance
        }
        
        self.titleTextAttributes = titleTextAttributes
        self.barTintColor = barTintColor
        self.tintColor = tintColor
    }
}

internal extension UITabBar {
    
    func configureLockAppearance() {
        
        self.tintColor = StyleKit.wirelessBlue
    }
}
