//
//  AppDelegate.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import Bluetooth
import GATT
import CoreLock

#if os(iOS)
import UIKit
import CoreBluetooth
import CoreLocation
#endif

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // print app info
        log("Launching SmartLock v\(AppVersion) Build \(AppBuild)")
        
        // setup logging
        LockManager.shared.log = { log("📱 LockManager: " + $0) }
        
        // handle url
        if let url = launchOptions?[UIApplicationLaunchOptionsKey.url] as? URL {
            
            guard openURL(url)
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
        
        return openURL(url)
    }
}

private extension AppDelegate {
    
    func openURL(_ url: URL) -> Bool {
        
        if url.isFileURL {
            
            // parse eKey file
            guard let data = try? Data(contentsOf: url),
                let newKey = try? JSONDecoder().decode(NewKey.Invitation.self, from: data)
                else { return false }
            
            // only one key per lock
            guard Store.shared[lock: newKey.lock] == nil else {
                self.window!.rootViewController?.showErrorAlert("You already have a key for lock \(newKey.lock).")
                return false
            }
            
            // show NewKeyReceiveVC
            let navigationController = UIStoryboard(name: "NewKeyInvitation", bundle: nil).instantiateInitialViewController() as! UINavigationController
            
            let newKeyVC = navigationController.topViewController as! NewKeyRecieveViewController
            
            newKeyVC.newKey = newKey
            
            self.window!.rootViewController?.present(navigationController, animated: true, completion: nil)
            
            return true
            
        } else {
            
            // handle custom URL
            
            return false
        }
    }
}

