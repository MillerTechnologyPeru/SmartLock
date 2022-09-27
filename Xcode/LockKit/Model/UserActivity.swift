//
//  UserActivity.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/18/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import Intents

#if canImport(CoreSpotlight)
import CoreSpotlight
#endif

#if canImport(MobileCoreServices)
import MobileCoreServices
#endif

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// `NSUserActivity` type
public enum AppActivityType: String {
    
    /// App activity for actions.
    case action = "com.colemancda.lock.activity.action"
    
    /// App activity for handoff for data viewing.
    case view = "com.colemancda.lock.activity.view"
    
    /// App activity that takes you to a specific screen (usually with a list of data).
    case screen = "com.colemancda.lock.activity.screen"
}

public enum AppActivity: Equatable, Hashable {
    
    case screen(Screen)
    case view(ViewData)
    case action(Action)
}

public extension AppActivity {
    
    enum ViewData: Equatable, Hashable {
        
        case lock(UUID)
    }
    
    enum Action: Equatable, Hashable {
        
        case shareKey(UUID)
        case unlock(UUID)
    }
    
    enum Screen: String {
        
        case nearbyLocks
        case keys
        case events
    }
}

public protocol AppActivityData {
    
    static var activityDataType: AppActivity.DataType { get }
}

extension LockCache: AppActivityData {
    
    public static var activityDataType: AppActivity.DataType { return .lock }
}

public extension AppActivity {
    
    init?(type: AppActivityType, rawValue: String) {
        
        switch type {
        case .screen:
            guard let screen = Screen(rawValue: rawValue)
                else { return nil }
            self = .screen(screen)
        case .action:
            guard let action = Action(rawValue: rawValue)
                else { return nil }
            self = .action(action)
        case .view:
            guard let viewData = ViewData(rawValue: rawValue)
                else { return nil }
            self = .view(viewData)
        }
    }
    
    var type: AppActivityType {
        
        switch self {
        case .action: return .action
        case .screen: return .screen
        case .view: return .view
        }
    }
}

private extension AppActivity {
    
    static let separator = "/"
}

extension AppActivity.ViewData: RawRepresentable {
    
    public init?(rawValue: String) {
        
        let subcomponents = rawValue
            .components(separatedBy: AppActivity.separator)
            .filter { $0.isEmpty == false }
        
        guard let typeString = subcomponents.first,
            let type = AppActivity.DataType(rawValue: typeString)
            else { return nil }
        
        switch type {
        case .lock:
            guard subcomponents.count == 2,
                let uuid = UUID(uuidString: String(subcomponents[1]))
                else { return nil }
            self = .lock(uuid)
        }
    }
    
    public var rawValue: String {
        
        let components: [String]
        
        switch self {
        case let .lock(identifier):
            components = [AppActivity.DataType.lock.rawValue, identifier.uuidString]
        }
        
        return components.reduce("", { $0 + AppActivity.separator + $1 })
    }
}

extension AppActivity.Action: RawRepresentable {
    
    public init?(rawValue: String) {
        
        let subcomponents = rawValue
            .components(separatedBy: AppActivity.separator)
            .filter { $0.isEmpty == false }
        
        guard let typeString = subcomponents.first,
            let type = AppActivity.ActionType(rawValue: typeString)
            else { return nil }
        
        switch type {
        case .unlock:
            guard subcomponents.count == 2,
                let uuid = UUID(uuidString: String(subcomponents[1]))
                else { return nil }
            self = .unlock(uuid)
        case .shareKey:
            guard subcomponents.count == 2,
                let uuid = UUID(uuidString: String(subcomponents[1]))
                else { return nil }
            self = .shareKey(uuid)
        }
    }
    
    public var rawValue: String {
        
        let components: [String]
        
        switch self {
        case let .unlock(identifier):
            components = [AppActivity.ActionType.unlock.rawValue, identifier.uuidString]
        case let .shareKey(identifier):
            components = [AppActivity.ActionType.shareKey.rawValue, identifier.uuidString]
        }
        
        return components.reduce("", { $0 + AppActivity.separator + $1 })
    }
}

public extension AppActivity {
    
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
}

public extension NSUserActivity {
    
    @MainActor
    convenience init(_ activity: AppActivity) {
        
        switch activity {
        case let .screen(screen):
            self.init(activityType: .screen, userInfo: [
                .screen: screen.rawValue as NSString
                ])
            #if canImport(CoreSpotlight)
            let attributes = CSSearchableItemAttributeSet(itemContentType: screen.rawValue)
            switch screen {
            case .nearbyLocks:
                self.title = "Nearby Locks" //R.string.localizable.userActivityNearbyLocksTitle()
                attributes.contentDescription = "Nearby Locks" //R.string.localizable.userActivityNearbyLocksDescription()
                //attributes.thumbnailData = UIImage(lockKit: "activityNear")?.pngData()
            case .keys:
                self.title = "Keys" //R.string.localizable.userActivityKeysTitle()
                attributes.contentDescription = "Keys" //R.string.localizable.userActivityKeysDescription()
                //attributes.thumbnailData = UIImage(lockKit: "activityLock")?.pngData()
            case .events:
                self.title = "History" //R.string.localizable.userActivityEventsTitle()
                attributes.contentDescription = "Lock events" //R.string.localizable.userActivityEventsDescription()
            }
            self.contentAttributeSet = attributes
            #endif
            self.isEligibleForSearch = false
            self.isEligibleForHandoff = true
            self.isEligibleForPublicIndexing = true // show in Siri Shortcuts gallery
            #if os(iOS) || os(watchOS)
            self.isEligibleForPrediction = true
            #endif
        case let .view(.lock(lockIdentifier)):
            self.init(activityType: .view, userInfo: [
                .lock: lockIdentifier.uuidString as NSString
                ])
            if let lockCache = Store.shared.applicationData.locks[lockIdentifier] {
                self.title = lockCache.name
                #if canImport(CoreSpotlight)
                self.contentAttributeSet = SearchableLock(id: lockIdentifier, cache: lockCache).searchableAttributeSet()
                #endif
            } else {
                self.title = "Lock \(lockIdentifier)"
            }
            self.isEligibleForSearch = true // use Spotlight instead
            self.isEligibleForHandoff = true
            self.isEligibleForPublicIndexing = true // show in Siri Shortcuts gallery,
            #if os(iOS) || os(watchOS)
            self.isEligibleForPrediction = false
            #endif
        case let .action(.shareKey(lockIdentifier)):
            self.init(activityType: .action, userInfo: [
                .action: AppActivity.ActionType.shareKey.rawValue as NSString,
                .lock: lockIdentifier.uuidString as NSString
                ])
            #if canImport(CoreSpotlight)
            let attributes = CSSearchableItemAttributeSet(itemContentType: UTType.text.identifier)
            //attributes.thumbnailData = UIImage(lockKit: "activityNewKey")?.pngData()
            self.contentAttributeSet = attributes
            #endif
            if let lockCache = Store.shared[lock: lockIdentifier] {
                self.title = "Share Key for \(lockCache.name)"
            } else {
                self.title = "Share Key for \(lockIdentifier)"
            }
            self.isEligibleForSearch = false
            self.isEligibleForHandoff = false
            #if os(iOS) || os(watchOS)
            self.isEligibleForPrediction = true
            #endif
        case let .action(.unlock(lockIdentifier)):
            self.init(activityType: .action, userInfo: [
                .action: AppActivity.ActionType.unlock.rawValue as NSString,
                .lock: lockIdentifier.uuidString as NSString
                ])
            if let lockCache = Store.shared[lock: lockIdentifier] {
                self.title = "Unlock \"\(lockCache.name)\""
            } else {
                self.title = "Unlock \(lockIdentifier)"
            }
            self.isEligibleForSearch = false
            self.isEligibleForHandoff = false
            #if os(iOS) || os(watchOS)
            if #available(iOS 12.0, watchOS 5.0, *) {
                self.isEligibleForPrediction = true
                self.suggestedInvocationPhrase = "Unlock my door"
            }
            #endif
        }
        
        switch activity {
        case let .action(action):
            self.persistentIdentifier = action.rawValue
        case let .screen(screen):
            self.persistentIdentifier = screen.rawValue
        case let .view(view):
            self.persistentIdentifier = view.rawValue
        }
    }
    
    private convenience init(activityType: AppActivityType, userInfo: [AppActivity.UserInfo: NSObject]) {
        
        self.init(activityType: activityType.rawValue)
        var data = [String: Any](minimumCapacity: userInfo.count)
        for (key, value) in userInfo {
            data[key.rawValue] = value
        }
        self.userInfo = data
        self.requiredUserInfoKeys = Set(userInfo.keys.lazy.map { $0.rawValue })
    }
}
