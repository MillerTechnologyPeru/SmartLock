//
//  ExtensionDelegate.swift
//  Watch Extension
//
//  Created by Alsey Coleman Miller on 8/28/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import WatchKit
import CoreBluetooth
import CoreLocation
import CoreLock
import LockKit

final class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    var shared: ExtensionDelegate { return WKExtension.shared().delegate as! ExtensionDelegate }
    
    let appLaunch = Date()

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        
        // print app info
        log("⌚️ Launching SmartLock Watch v\(AppVersion) Build \(AppBuild)")
        
        // setup logging
        Store.shared.lockManager.log = { log("🔒 LockManager: " + $0) }
        SessionController.shared.log = { log("📱 SessionController: " + $0) }
        
        // sync with iOS app on launch
        SessionController.shared.context = {
            Store.shared.applicationData = $0.applicationData
        }
        Store.shared.syncApp()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        log("⌚️ Did become active")
        
        // load updated lock information
        Store.shared.loadCache()
        
        // scan for locks and sync with iPhone
        refresh()
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        
        log("⌚️ Will resign active")
        
        #if DEBUG
        let updateInterval: TimeInterval = 10
        #else
        let updateInterval: TimeInterval = 60 * 3
        #endif
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date() + updateInterval, userInfo: nil) { (error) in
            if let error = error {
                log("⚠️ Could not end background task: \(error.localizedDescription)")
                return
            }
            log("Background task completed")
        }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        log("⌚️ Handle background tasks")
                
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                refresh { backgroundTask.setTaskCompleted(refreshSnapshot: true) }
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                refresh {
                    snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date() + 60, userInfo: nil)
                }
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                refresh { connectivityTask.setTaskCompleted(refreshSnapshot: true) }
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompleted(refreshSnapshot: false)
            //case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                //relevantShortcutTask.setTaskCompleted(refreshSnapshot: false)
            //case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                //intentDidRunTask.setTaskCompleted(refreshSnapshot: false)
            default:
                // make sure to complete unhandled task types
                refresh { task.setTaskCompleted(refreshSnapshot: true) }
            }
        }
    }
}

internal extension ExtensionDelegate {
    
    func refresh(completion: (() -> ())? = nil) {
        
        // sync with iPhone
        if SessionController.shared.activationState == .activated,
            SessionController.shared.isReachable {
            Store.shared.syncApp(completion: { [unowned self] in
                self.scan(completion: completion)
            })
        } else {
            self.scan(completion: completion)
        }
    }
    
    /// Scan for nearby locks in the background.
    func scan(completion: (() -> ())? = nil) {
        
        // scan for locks
        async {
            defer { mainQueue { completion?() } }
            do {
                // scan for locks
                try Store.shared.scan(duration: 1.0)
                // make sure each stored lock is visible
                for lock in Store.shared.locks.value.keys {
                    let _ = try Store.shared.device(for: lock, scanDuration: 1.0)
                }
            } catch { log("⚠️ Unable to scan: \(error)") }
        }
    }
}

internal extension WKRefreshBackgroundTask {
    
    /// Marks the task as complete and indicates whether the system should take a new snapshot of the app.
    func setTaskCompleted(refreshSnapshot: Bool) {
        if #available(watchOSApplicationExtension 4.0, *) {
            setTaskCompletedWithSnapshot(refreshSnapshot)
        } else {
            setTaskCompleted()
        }
    }
}
