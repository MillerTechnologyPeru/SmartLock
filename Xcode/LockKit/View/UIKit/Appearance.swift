//
//  Appearance.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

#if canImport(UIKit) && os(iOS)
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
        let barButtonItemAppearance = UIBarButtonItemAppearance(style: .plain)
        barButtonItemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        barButtonItemAppearance.disabled.titleTextAttributes = [.foregroundColor: UIColor.lightText]
        barButtonItemAppearance.highlighted.titleTextAttributes = [.foregroundColor: UIColor.label]
        barButtonItemAppearance.focused.titleTextAttributes = [.foregroundColor: UIColor.white]
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = barTintColor
        appearance.titleTextAttributes = titleTextAttributes
        appearance.largeTitleTextAttributes = titleTextAttributes
        appearance.buttonAppearance = barButtonItemAppearance
        appearance.backButtonAppearance = barButtonItemAppearance
        appearance.doneButtonAppearance = barButtonItemAppearance
        self.standardAppearance = appearance
        self.compactAppearance = appearance
        self.scrollEdgeAppearance = appearance
        self.largeTitleTextAttributes = titleTextAttributes
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

#endif
