//
//  TabBarController.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/18/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreLock
import LockKit

final class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if targetEnvironment(macCatalyst)
        select(NearbyLocksViewController.self)
        #endif
    }
    
    internal func select <T: UIViewController> (_ viewController: T.Type, _ block: ((T) -> ())? = nil) {
        loadViewIfNeeded()
        for (index, child) in (viewControllers ?? []).enumerated() {
            guard let navigationController = child as? UINavigationController
                else { assertionFailure(); continue }
            guard let viewController = navigationController.viewControllers.first as? T
                else { continue }
            selectedIndex = index
            navigationController.popToRootViewController(animated: false)
            block?(viewController)
            return
        }
        assertionFailure("Did not transition")
    }
}
