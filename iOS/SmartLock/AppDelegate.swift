//
//  AppDelegate.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import CoreLocation
import UserNotifications
import CoreSpotlight
import Bluetooth
import GATT
import CoreLock
import LockKit
import JGProgressHUD
import OpenCombine

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    // MARK: - Properties

    var window: UIWindow?
    
    private(set) var didBecomeActive: Bool = false
    
    let appLaunch = Date()
    
    lazy var bundle = Bundle.Lock(rawValue: Bundle.main.bundleIdentifier ?? "") ?? .app
    
    #if DEBUG || targetEnvironment(macCatalyst)
    private var updateTimer: Timer?
    #endif
    
    private var locksObserver: OpenCombine.AnyCancellable?
    
    // MARK: - UIApplicationDelegate
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Create logging file
        Log.shared = .mainApp
        
        // print app info
        log("\(bundle.symbol) Launching SmartLock v\(AppVersion) Build \(AppBuild)")
        
        #if DEBUG
        defer { log("\(bundle.symbol) App finished launching in \(String(format: "%.3f", Date().timeIntervalSince(appLaunch)))s") }
        #endif
        
        // set global appearance
        UIView.configureLockAppearance()
        
        #if DEBUG
        do {
            try R.validate()
            try RLockKit.validate()
        } catch {
            print(error)
            assertionFailure("Could not validate R.swift \(error)")
        }
        #endif
        
        // load store singleton
        let _ = Store.shared
        
        // setup logging
        LockManager.shared.log = { log("🔒 LockManager: " + $0) }
        BeaconController.shared.log = { log("📶 \(BeaconController.self): " + $0) }
        SpotlightController.shared.log = { log("🔦 \(SpotlightController.self): " + $0) }
        WatchController.shared.log = { log("⌚️ \(WatchController.self): " + $0) }
        if #available(iOS 10.0, *) {
            UserNotificationCenter.shared.log = { log("📨 \(UserNotificationCenter.self): " + $0) }
        }
        
        // request permissions
        //BeaconController.shared.allowsBackgroundLocationUpdates = true
        BeaconController.shared.requestAlwaysAuthorization()
        if #available(iOS 10.0, *) {
            UserNotificationCenter.shared.requestAuthorization()
        }
        
        // handle notifications
        if #available(iOS 10.0, *) {
            UserNotificationCenter.shared.handleActivity = { [unowned self] (activity) in
                mainQueue { self.handle(activity: activity) }
            }
        }
        
        // setup watch
        if WatchController.isSupported {
            WatchController.shared.activate()
            WatchController.shared.keys = { Store.shared[key: $0] }
            WatchController.shared.context = .init(
                applicationData: Store.shared.applicationData
            )
            locksObserver = Store.shared.locks.sink { _ in
                WatchController.shared.context = .init(
                    applicationData: Store.shared.applicationData
                )
            }
        }
        
        #if targetEnvironment(macCatalyst)
        // scan periodically in macOS
        setupBackgroundUpdates()
        #else
        // background fetch in iOS
        application.setMinimumBackgroundFetchInterval(60 * 10)
        #endif
        
        // handle url
        if let url = launchOptions?[.url] as? URL {
            guard open(url: url)
                else { return false }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        log("\(bundle.symbol) Will resign active")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        let bundle = self.bundle
        log("\(bundle.symbol) Did enter background")
        logBackgroundTimeRemaining()
        
        // update beacons
        BeaconController.shared.scanBeacons()
        // scan in background
        let beaconTask = UIApplication.shared.beginBackgroundTask(withName: bundle.rawValue, expirationHandler: {
            log("\(bundle.symbol) Background task expired")
        })
        DispatchQueue.bluetooth.async { [unowned self] in
            do {
                // scan for locks
                try Store.shared.scan(duration: 3.0)
                // make sure each stored lock is visible
                for lock in Store.shared.locks.value.keys {
                    let _ = try Store.shared.device(for: lock, scanDuration: 1.0)
                }
            } catch { log("⚠️ Unable to scan: \(error.localizedDescription)") }
            // attempt to sync with iCloud
            DispatchQueue.cloud.async {
                do { try Store.shared.syncCloud() }
                catch { log("⚠️ Unable to sync: \(error.localizedDescription)") }
                mainQueue { self.logBackgroundTimeRemaining() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    log("\(bundle.symbol) Background task ended")
                    UIApplication.shared.endBackgroundTask(beaconTask)
                }
            }
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        log("\(bundle.symbol) Will enter foreground")
        
        BeaconController.shared.scanBeacons()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        log("\(bundle.symbol) Did become active")
        
        didBecomeActive = true
        
        // update cache if modified by extension
        Store.shared.loadCache()
                        
        BeaconController.shared.scanBeacons()
        
        // attempt to scan for all known locks if they are not in central cache
        DispatchQueue.bluetooth.async {
            do {
                for lock in Store.shared.locks.value.keys {
                    let _ = try Store.shared.device(for: lock, scanDuration: 1.0)
                }
            } catch { log("⚠️ Unable to scan: \(error.localizedDescription)") }
        }
        
        // attempt to sync with iCloud
        tabBarController.syncCloud()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        log("\(bundle.symbol) Will terminate")
        
        BeaconController.shared.scanBeacons()

    }
    
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        return open(url: url)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return open(url: url)
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let bundle = self.bundle
        log("\(bundle.symbol) Perform background fetch")
        logBackgroundTimeRemaining()
        
        BeaconController.shared.scanBeacons()
        
        // 30 sec max background fetch
        var result: UIBackgroundFetchResult = .noData
        let applicationData = Store.shared.applicationData
        let information = Array(Store.shared.lockInformation.value.values)
        DispatchQueue.bluetooth.async { [unowned self] in
            do {
                // scan for locks
                try Store.shared.scan(duration: 5.0)
                // make sure each stored lock is visible
                let locks = Store.shared.locks.value
                    .lazy
                    .sorted(by: { $0.value.key.created < $1.value.key.created })
                    .lazy
                    .map { $0.key }
                    .lazy
                    .filter { Store.shared.device(for: $0) == nil }
                    .prefix(10)
                // scan for locks not found
                for lock in locks {
                    let _ = try Store.shared.device(for: lock, scanDuration: 1.0)
                }
            } catch {
                log("⚠️ Unable to scan: \(error.localizedDescription)")
                result = .failed
            }
            // attempt to sync with iCloud
            DispatchQueue.cloud.async {
                do { try Store.shared.syncCloud() }
                catch {
                    log("⚠️ Unable to sync: \(error.localizedDescription)")
                    result = .failed
                }
                if result != .failed {
                    if applicationData == Store.shared.applicationData,
                        information == Array(Store.shared.lockInformation.value.values) {
                        result = .noData
                    } else {
                        result = .newData
                    }
                }
                mainQueue { self.logBackgroundTimeRemaining() }
                log("\(bundle.symbol) Background fetch ended")
                completionHandler(result)
            }
        }
    }
    
    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        log("Continue activity \(userActivity.activityType)")
        if #available(iOS 12.0, *),
            let persistentIdentifier = userActivity.persistentIdentifier {
            log("\(persistentIdentifier)")
        }
        log("\((userActivity.userInfo as NSDictionary?)?.description ?? "")")
        var userInfo = [AppActivity.UserInfo: Any](minimumCapacity: userActivity.userInfo?.count ?? 0)
        for (key, value) in userActivity.userInfo ?? [:] {
            guard let key = key as? String,
                let userInfoKey = AppActivity.UserInfo(rawValue: key)
                else { continue }
            userInfo[userInfoKey] = value
        }
        
        switch userActivity.activityType {
        case CSSearchableItemActionType:
            guard let activityIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
                let activity = AppActivity.ViewData(rawValue: activityIdentifier)
                else { return false }
            self.handle(activity: .view(activity))
            return false
        case NSUserActivityTypeBrowsingWeb:
            return false
        case AppActivityType.screen.rawValue:
            guard let screenString = userInfo[.screen] as? String,
                let screen = AppActivity.Screen(rawValue: screenString)
                else { return false }
            self.handle(activity: .screen(screen))
        case AppActivityType.view.rawValue:
            if let lockString = userInfo[.lock] as? String,
                let lock = UUID(uuidString: lockString) {
                self.handle(activity: .view(.lock(lock)))
            } else {
                return false
            }
        case AppActivityType.action.rawValue:
            guard let actionString = userInfo[.action] as? String,
                let action = AppActivity.ActionType(rawValue: actionString)
                else { return false }
            switch action {
            case .unlock:
                guard let lockString = userInfo[.lock] as? String,
                    let lock = UUID(uuidString: lockString)
                    else { return false }
                self.handle(activity: .action(.unlock(lock)))
            case .shareKey:
                guard let lockString = userInfo[.lock] as? String,
                    let lock = UUID(uuidString: lockString)
                    else { return false }
                self.handle(activity: .action(.shareKey(lock)))
            }
        default:
            return false
        }
        
        return true
    }
}

extension AppDelegate {
    
    var tabBarController: TabBarController {
        guard let tabBarController = window?.rootViewController as? TabBarController
            else { fatalError() }
        return tabBarController
    }
}

private extension AppDelegate {
    
    private static let intervalFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
    
    func logBackgroundTimeRemaining() {
        
        let backgroundTimeRemaining = UIApplication.shared.backgroundTimeRemaining
        let start = Date()
        let timeString = type(of: self).intervalFormatter.string(from: start, to: start + backgroundTimeRemaining)
        log("\(bundle.symbol) Background time remaining: \(timeString)")
    }
}

#if DEBUG || targetEnvironment(macCatalyst)
private extension AppDelegate {
    
    @available(macOS 10.13, iOS 10.0, *)
    func setupBackgroundUpdates() {
        
        let interval = 90.0
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateBackground()
        }
    }
    
    func updateBackground() {
        
        let bundle = self.bundle
        log("\(bundle.symbol) Will update data")
        
        DispatchQueue.bluetooth.async {
            do {
                // scan for locks
                try Store.shared.scan(duration: 3.0)
                // make sure each stored lock is visible
                for lock in Store.shared.locks.value.keys {
                    let _ = try Store.shared.device(for: lock, scanDuration: 1.0)
                }
            } catch { log("⚠️ Unable to scan: \(error.localizedDescription)") }
            // attempt to sync with iCloud
            DispatchQueue.cloud.async {
                do { try Store.shared.syncCloud() }
                catch { log("⚠️ Unable to sync: \(error.localizedDescription)") }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    log("\(bundle.symbol) Updated data")
                }
            }
        }
    }
}
#endif

// MARK: - URL Handling

internal extension AppDelegate {
    
    func open(url: URL) -> Bool {
        
        if url.isFileURL {
            return open(file: url)
        } else if let lockURL = LockURL(rawValue: url) {
            open(url: lockURL)
            return true
        } else {
            return false
        }
    }
    
    func open(file url: URL) -> Bool {
        
        // parse eKey file
        guard let data = try? Data(contentsOf: url),
            let newKey = try? JSONDecoder().decode(NewKey.Invitation.self, from: data)
            else { return false }
        
        return tabBarController.open(newKey: newKey)
    }
    
    func open(url: LockURL) {
        tabBarController.handle(url: url)
    }
}

// MARK: - LockActivityHandling

extension AppDelegate: LockActivityHandling {
    
    func handle(url: LockURL) {
        tabBarController.handle(url: url)
    }
    
    func handle(activity: AppActivity) {
        tabBarController.handle(activity: activity)
    }
}
