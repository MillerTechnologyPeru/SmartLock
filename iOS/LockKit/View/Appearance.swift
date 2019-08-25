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
        
        UINavigationBar.configureAppearance()
        UITabBar.configureAppearance()
    }
}

internal extension UINavigationBar {
    
    static func configureAppearance() {
        
        let barTintColor = StyleKit.wirelessBlue
        let tintColor: UIColor = .white
        let titleTextAttributes: [NSAttributedString.Key : Any] = [
            .foregroundColor: UIColor.white
        ]
        
        if #available(iOSApplicationExtension 11.0, *) {
            self.appearance().largeTitleTextAttributes = titleTextAttributes
        }
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = barTintColor
            appearance.titleTextAttributes = titleTextAttributes
            appearance.largeTitleTextAttributes = titleTextAttributes
            self.appearance().standardAppearance = appearance
            self.appearance().compactAppearance = appearance
            self.appearance().scrollEdgeAppearance = appearance
        }
        
        self.appearance().titleTextAttributes = titleTextAttributes
        self.appearance().barTintColor = barTintColor
        self.appearance().tintColor = tintColor
        
    }
}

internal extension UITabBar {
    
    static func configureAppearance() {
        
        self.appearance().tintColor = StyleKit.wirelessBlue
    }
}
