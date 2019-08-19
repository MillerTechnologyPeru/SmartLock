//
//  TabBarController.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/18/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock
import UIKit

final class TabBarController: UITabBarController {
    
    private func select <T: UIViewController> (_ viewController: T.Type, _ block: (T) -> ()) {
        loadViewIfNeeded()
        for (index, child) in (viewControllers ?? []).enumerated() {
            guard let navigationController = child as? UINavigationController
                else { assertionFailure(); continue }
            guard let viewController = navigationController.viewControllers.first as? T
                else { continue }
            selectedIndex = index
            block(viewController)
            return
        }
        assertionFailure("Did not transition")
    }
}

// MARK: - LockActivityHandling

extension TabBarController: LockActivityHandlingViewController {
    
    func handle(activity: AppActivity) {
        fatalError()
    }
    
    func handle(url: LockURL) {
        
        switch url {
        case let .setup(lock: identifier, secret: secret):
            select(NearbyLocksViewController.self) {
                $0.setup(lock: identifier, secret: secret)
            }
        case let .unlock(lock: identifier):
            select(KeysViewController.self) {
                $0.select(lock: identifier)
            }
        case let .newKey(invitation):
            open(newKey: invitation)
        }
    }
}
