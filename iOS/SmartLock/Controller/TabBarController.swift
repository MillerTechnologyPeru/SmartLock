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
    
    private func select <T: UIViewController> (_ viewController: T.Type, _ block: ((T) -> ())? = nil) {
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

// MARK: - LockActivityHandling

extension TabBarController: LockActivityHandlingViewController {
    
    func handle(activity: AppActivity) {
        
        switch activity {
        case .screen(.nearbyLocks):
            // show nearby locks
            select(NearbyLocksViewController.self)
        case .screen(.keys):
            // show keys
            select(KeysViewController.self)
        case .view(.lock):
            // forward
            select(KeysViewController.self) {
                $0.handle(activity: activity)
            }
        case .action(.unlock):
            // forward
            select(KeysViewController.self) {
                $0.handle(activity: activity)
            }
        case let .action(.shareKey(identifier)):
            // show modal form
            shareKey(lock: identifier)
        }
    }
    
    func handle(url: LockURL) {
        
        switch url {
        case let .setup(lock: identifier, secret: secret):
            // setup in background
            select(NearbyLocksViewController.self) {
                $0.setup(lock: identifier, secret: secret)
            }
        case .unlock:
            // dont actually unlock, show UI
            select(KeysViewController.self) {
                $0.handle(url: url)
            }
        case let .newKey(invitation):
            // show modal form
            open(newKey: invitation)
        }
    }
}
