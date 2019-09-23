//
//  UserNotification.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UserNotifications
import MobileCoreServices

@available(iOS 10.0, *)
public final class UserNotificationCenter {
    
    // MARK: - Initialization
    
    public static let shared = UserNotificationCenter()
    
    private init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
        self.notificationCenter.delegate = delegate
    }
    
    // MARK: - Properties
    
    public var log: ((String) -> ())?
    
    private let notificationCenter: UNUserNotificationCenter
    
    private lazy var delegate = Delegate(self)
    
    public var handleActivity: ((AppActivity) -> ())?
    
    // MARK: - Methods
    
    public func requestAuthorization() {
        
        notificationCenter.requestAuthorization(options: [.alert]) { [weak self] (didAuthorize, error) in
            self?.log?("Authorization: \(didAuthorize) \(error?.localizedDescription ?? "")")
        }
    }
    
    public func postUnlockNotification(for lock: UUID, cache: LockCache, delay: TimeInterval = 0.1) {
        
        let action = AppActivity.Action.unlock(lock)
        
        // Create Notification content
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = cache.name
        notificationContent.subtitle = "Tap to unlock"
        
        if let imageURL = AssetExtractor.shared.url(for: cache.key.permission.type.image),
            let attachment = try? UNNotificationAttachment(
                identifier: String(reflecting: cache.key.permission.type),
                url: imageURL,
                options: [UNNotificationAttachmentOptionsTypeHintKey: kUTTypePNG as String]) {
            
            notificationContent.attachments = [attachment]
        }
        
        // Create Notification trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // Create a notification request with the above components
        let request = UNNotificationRequest(
            identifier: action.rawValue,
            content: notificationContent,
            trigger: trigger
        )
        
        // Add this notification to the UserNotificationCenter
        notificationCenter.add(request) { [weak self] error in
           self?.log?("Notified "
            + notificationContent.title + " - " + notificationContent.subtitle
            + " " + "\(error?.localizedDescription ?? "")")
        }
    }
    
    public func removeUnlockNotification(for lock: UUID) {
        
        removeUnlockNotification(for: [lock])
    }
    
    public func removeUnlockNotification(for locks: [UUID]) {
        
        let identifiers = locks.map { AppActivity.Action.unlock($0).rawValue }
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    public func postNewKeyShareNotification(delay: TimeInterval = 0.1) {
        
        
    }
    
    public func removeAllNotfications() {
        
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
}

@available(iOS 10.0, *)
private extension UserNotificationCenter {
    
    @objc(UserNotificationCenterDelegate)
    final class Delegate: NSObject, UNUserNotificationCenterDelegate {
        
        private weak var notificationCenter: UserNotificationCenter?
        
        fileprivate init(_ notificationCenter: UserNotificationCenter) {
            self.notificationCenter = notificationCenter
        }
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            
            let identifier = response.notification.request.identifier
            
            notificationCenter?.log?("Recieved response \(response.actionIdentifier) for \(identifier)")
            
            if let action = AppActivity.Action(rawValue: identifier) {
                notificationCenter?.handleActivity?(.action(action))
            } else {
                assertionFailure()
            }
            
            completionHandler()
        }
    }
}
