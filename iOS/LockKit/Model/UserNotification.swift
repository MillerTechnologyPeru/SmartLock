//
//  UserNotification.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UserNotifications

@available(iOS 10.0, *)
public final class UserNotificationCenter {
    
    // MARK: - Initialization
    
    static let shared = UserNotificationCenter()
    
    private init(notificationCenter: UNUserNotificationCenter = .current()) {
        self.notificationCenter = notificationCenter
    }
    
    // MARK: - Properties
    
    public var log: ((String) -> ())?
    
    private let notificationCenter: UNUserNotificationCenter
    
    // MARK: - Methods
    
    public func postUnlockNotification(for lock: UUID, name: String, delay: TimeInterval = 0.1) {
        
        let action = AppActivity.Action.unlock(lock)
        
        // Create Notification content
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = name
        notificationContent.subtitle = "Tap to unlock"
        
        // Create Notification trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        // Create a notification request with the above components
        let request = UNNotificationRequest(identifier: action.rawValue, content: notificationContent, trigger: trigger)
        
        // Add this notification to the UserNotificationCenter
        notificationCenter.add(request) { [weak self] error in
           self?.log?("Notified: \(error?.localizedDescription ?? "")")
        }
    }
    
    public func removeUnlockNotification(for lock: UUID) {
        removeUnlockNotification(for: [lock])
    }
    
    public func removeUnlockNotification(for locks: [UUID]) {
        
        let identifiers = locks.map { AppActivity.Action.unlock($0).rawValue }
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
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
        
        
    }
}
