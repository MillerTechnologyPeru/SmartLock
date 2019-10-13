//
//  ActivityHandling.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreLock
import LockKit

// MARK: - TabBarController

extension TabBarController: LockActivityHandlingViewController {
    
    func handle(activity: AppActivity) {
        
        switch activity {
        case .screen(.nearbyLocks):
            // show nearby locks
            select(NearbyLocksViewController.self)
        case .screen(.keys):
            // show keys
            select(KeysViewController.self)
        case .screen(.events):
            // show keys
            select(LockEventsViewController.self)
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

// MARK: - KeysViewController

extension KeysViewController: LockActivityHandlingViewController {
    
    func handle(url: LockURL) {
        
        switch url {
        case let .unlock(lock: identifier):
            select(lock: identifier, animated: false)
        case .newKey,
             .setup:
            AppDelegate.shared.handle(url: url)
        }
    }
    
    func handle(activity: AppActivity) {
        
        switch activity {
        case .screen(.keys):
            return
        case .screen(.nearbyLocks),
             .screen(.events):
            AppDelegate.shared.handle(activity: activity)
        case let .view(.lock(identifier)):
            select(lock: identifier, animated: false)
        case let .action(.unlock(identifier)):
            select(lock: identifier, animated: false)?.handle(activity: activity)
        case .action(.shareKey):
            AppDelegate.shared.handle(activity: activity)
        }
    }
}

// MARK: - LockViewController

extension LockViewController: LockActivityHandlingViewController {
    
    public func handle(url: LockURL) {
        
        switch url {
        case .newKey,
             .setup:
            AppDelegate.shared.handle(url: url)
        case let .unlock(lock: identifier):
            if identifier == self.lockIdentifier {
                return // do nothing
            } else {
                AppDelegate.shared.handle(url: url)
            }
        }
    }
    
    public func handle(activity: AppActivity) {
        
        switch activity {
        case let .action(.shareKey(identifier)):
            shareKey(lock: identifier)
        case let .action(.unlock(identifier)):
            if identifier == self.lockIdentifier {
                self.unlock()
            } else {
                AppDelegate.shared.handle(activity: activity)
            }
        case let .view(.lock(identifier)):
            if identifier == self.lockIdentifier {
                return // do nothing, already visible
            } else {
                AppDelegate.shared.handle(activity: activity)
            }
        case .screen:
            AppDelegate.shared.handle(activity: activity)
        }
    }
}
