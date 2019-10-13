//
//  AdaptiveNavigation.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

public extension UIViewController {
    
    func showAdaptiveDetail(_ viewController: UIViewController, sender: Any? = nil) {
        
        // iPhone
        if splitViewController?.viewControllers.count == 1 {
            
            self.show(viewController, sender: sender)
        }
            // iPad
        else {
            
            let navigationController = UINavigationController(rootViewController: viewController)
            
            self.showDetailViewController(navigationController, sender: sender)
        }
    }
}
