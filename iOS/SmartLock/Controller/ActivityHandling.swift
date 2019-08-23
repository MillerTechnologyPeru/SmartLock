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
        case .screen(.nearbyLocks):
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
