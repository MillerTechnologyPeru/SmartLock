//
//  UserActivity.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/18/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

/// `NSUserActivity` type
enum AppActivityType: String {
    
    /// App activity for actions.
    case action = "com.colemancda.lock.activity.action"
    
    /// App activity for handoff for data viewing.
    case view = "com.colemancda.lock.activity.view"
    
    /// App activity that takes you to a specific screen (usually with a list of data).
    case screen = "com.colemancda.lock.activity.screen"
}

enum AppActivity {
    
    case screen(Screen)
    case view(ViewData)
    case action(Action)
}

extension AppActivity {
    
    enum ViewData {
        
        case lock(UUID)
    }
    
    enum Action {
        
        case shareKey(UUID)
        case unlock(UUID)
    }
    
    enum UserInfo: String {
        
        case lock
        case screen
        case action
    }
    
    enum DataType: String {
        
        case lock
    }
    
    enum ActionType: String {
        
        case shareKey
        case unlock
    }
    
    enum Screen: String {
        
        case nearbyLocks
        case keys
    }
}

extension NSUserActivity {
    
    convenience init(_ activity: AppActivity) {
        
        switch activity {
        case let .screen(screen):
            self.init(activityType: .screen, userInfo: [
                .screen: screen.rawValue as NSString
                ])
            switch screen {
            case .nearbyLocks:
                self.title = "Nearby Locks"
            case .keys:
                self.title = "Keys"
            }
            self.isEligibleForSearch = false
            self.isEligibleForHandoff = true
            if #available(iOS 12.0, *) {
                self.isEligibleForPrediction = false
            }
        case let .view(.lock(lockIdentifier)):
            self.init(activityType: .view, userInfo: [
                .lock: lockIdentifier as NSUUID
                ])
            if let lockCache = Store.shared[lock: lockIdentifier] {
                self.title = lockCache.name
            } else {
                self.title = "Lock \(lockIdentifier)"
            }
            self.isEligibleForSearch = true
            self.isEligibleForHandoff = true
            if #available(iOS 12.0, *) {
                self.isEligibleForPrediction = false
            }
        case let .action(.shareKey(lockIdentifier)):
            self.init(activityType: .action, userInfo: [
                .action: AppActivity.ActionType.shareKey.rawValue as NSString,
                .lock: lockIdentifier as NSUUID
                ])
            if let lockCache = Store.shared[lock: lockIdentifier] {
                self.title = "Share Key for \(lockCache.name)"
            } else {
                self.title = "Share Key"
            }
            self.isEligibleForSearch = false
            self.isEligibleForHandoff = true
            if #available(iOS 12.0, *) {
                self.isEligibleForPrediction = true
            }
        case let .action(.unlock(lockIdentifier)):
            self.init(activityType: .action, userInfo: [
                .action: AppActivity.ActionType.unlock.rawValue as NSString,
                .lock: lockIdentifier as NSUUID
                ])
            if let lockCache = Store.shared[lock: lockIdentifier] {
                self.title = "Unlock \(lockCache.name)"
            } else {
                self.title = "Unlock \(lockIdentifier)"
            }
            self.isEligibleForSearch = false
            self.isEligibleForHandoff = true
            if #available(iOS 12.0, *) {
                self.isEligibleForPrediction = true
            }
        }
    }
    
    convenience init(activityType: AppActivityType, userInfo: [AppActivity.UserInfo: NSObject]) {
        
        self.init(activityType: activityType.rawValue)
        var data = [String: Any](minimumCapacity: userInfo.count)
        for (key, value) in userInfo {
            data[key.rawValue] = value
        }
        self.userInfo = data
        self.requiredUserInfoKeys = Set(userInfo.keys.lazy.map { $0.rawValue })
    }
}
