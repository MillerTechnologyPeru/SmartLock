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
import Bluetooth
import GATT
import CoreLock
import JGProgressHUD

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // print app info
        log("📱 Launching SmartLock v\(AppVersion) Build \(AppBuild)")
        
        // setup logging
        LockManager.shared.log = { log("🔒 LockManager: " + $0) }
        BeaconController.shared.log = { log("📶 BeaconController: " + $0) }
        
        // request permissions
        BeaconController.shared.requestAuthorization()
        
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
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        
        return open(url: url)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        
        print("Continue activity \(userActivity.activityType)")
        if #available(iOS 12.0, *),
            let persistentIdentifier = userActivity.persistentIdentifier {
            print("\(persistentIdentifier)")
        }
        print("\((userActivity.userInfo as NSDictionary?)?.description ?? "")")
        
        switch userActivity.activityType {
        //case CSSearchableItemActionType:
        //    return false
        case NSUserActivityTypeBrowsingWeb:
            return false
        case AppActivityType.screen.rawValue:
            guard let screenString = userActivity.userInfo?[AppActivity.UserInfo.screen] as? String,
                let screen = AppActivity.Screen(rawValue: screenString)
                else { return false }
            self.handle(activity: .screen(screen))
        case AppActivityType.view.rawValue:
            if let lock = userActivity.userInfo?[AppActivity.UserInfo.lock] as? UUID {
                self.handle(activity: .view(.lock(lock)))
            } else {
                return false
            }
        case AppActivityType.action.rawValue:
            guard let actionString = userActivity.userInfo?[AppActivity.UserInfo.action] as? String,
                let action = AppActivity.ActionType(rawValue: actionString)
                else { return false }
            switch action {
            case .unlock:
                guard let lock = userActivity.userInfo?[AppActivity.UserInfo.lock] as? UUID
                    else { return false }
                self.handle(activity: .action(.unlock(lock)))
            case .shareKey:
                guard let lock = userActivity.userInfo?[AppActivity.UserInfo.lock] as? UUID
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
