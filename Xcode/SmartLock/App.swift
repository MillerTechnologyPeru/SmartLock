//
//  SmartLockApp.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import SwiftUI
import LockKit

#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

@main
struct LockApp: App {
    
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    #elseif os(iOS) || os(tvOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    #endif
    
    var body: some Scene {
        
        // main window
        WindowGroup {
            ContentView()
                .environmentObject(Store.shared)
                .environment(\.managedObjectContext, Store.shared.managedObjectContext)
        }
        
        #if os(macOS) || os(iOS)
        // documents
        DocumentGroup(viewing: NewKey.Invitation.Document.self) { file in
            NewKeyInvitationView(invitation: file.document.invitation)
                .environmentObject(Store.shared)
        }
        #endif
        
        #if os(macOS)
        Window("Nearby", id: "nearby") {
            NavigationView {
                NearbyDevicesView()
                    .navigationDestination(for: AppNavigationLinkID.self) {
                        AppNavigationDestinationView(id: $0)
                    }
            }
            .environmentObject(Store.shared)
            .environment(\.managedObjectContext, Store.shared.managedObjectContext)
        }
        
        Window("Keys", id: "keys") {
            NavigationView {
                KeysView()
                    .navigationDestination(for: AppNavigationLinkID.self) {
                        AppNavigationDestinationView(id: $0)
                    }
            }
            .environmentObject(Store.shared)
            .environment(\.managedObjectContext, Store.shared.managedObjectContext)
        }
        
        Settings {
            //NavigationStack {
            //    SettingsView()
            //}
            Text("Settings")
            .environmentObject(Store.shared)
            .environment(\.managedObjectContext, Store.shared.managedObjectContext)
        }
        #endif
    }
    
    init() {
        // print app info
        log("Launching SmartLock v\(Bundle.InfoPlist.shortVersion) (\(Bundle.InfoPlist.version))")
        
        Task {
            try? await Task.sleep(timeInterval: 0.5)
            await LockApp.didLaunch()
        }
    }
}


private extension App {
    
    static func didLaunch() async {
        
        // load store singleton
        let _ = await Store.shared
        let _ = NetworkMonitor.shared
        
        // CloudKit discoverability
        do {
            guard try await Store.shared.cloud.accountStatus() == .available else { return }
            let status = try await Store.shared.cloud.requestPermissions()
            log("☁️ CloudKit permisions \(status == .granted ? "granted" : "not granted")")
        }
        catch { log("⚠️ Could not request CloudKit permissions. \(error.localizedDescription)") }
        
        // CloudKit push notifications
        do {
            guard try await Store.shared.cloud.accountStatus() == .available else { return }
            try await Store.shared.cloud.subcribeNewKeyShares()
        }
        catch { log("⚠️ Could subscribe to new shares. \(error)") }
    }
}

#if os(iOS) || os(tvOS)
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let appLaunch = Date()
    
    private(set) var didBecomeActive: Bool = false
    
    // MARK: - UIApplicationDelegate
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // set app appearance
        //UIView.configureLockAppearance()
        
        #if DEBUG
        defer { log("App finished launching in \(String(format: "%.3f", Date().timeIntervalSince(appLaunch)))s") }
        #endif
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        log("Will resign active")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        // only scan and sync in background when low power mode is disabled.
        guard ProcessInfo.processInfo.isLowPowerModeEnabled == false else { return }
        
        // scan in background
        Task {
            if await Store.shared.central.state == .poweredOn {
                let bluetoothTask = application.beginBackgroundTask(withName: "BluetoothScan", expirationHandler: {
                    log("Bluetooth Scan background task expired")
                })
                // scan for nearby devices
                do { try await Store.shared.scan(duration: 1.0) }
                catch { log("⚠️ Unable to scan: \(error.localizedDescription)") }
                // read information characteristic
                for device in Store.shared.peripherals.keys {
                    guard Store.shared.lockInformation[device] == nil
                        else { continue }
                    do { try await Store.shared.readInformation(for: device) }
                    catch { log("⚠️ Unable to read information: \(error.localizedDescription)") }
                }
                
                await MainActor.run {
                    self.logBackgroundTimeRemaining()
                    log("Bluetooth background task ended")
                    application.endBackgroundTask(bluetoothTask)
                }
            }
        }
        
        // attempt to sync with iCloud in background
        let cloudTask = application.beginBackgroundTask(withName: "iCloudSync", expirationHandler: {
            log("iCloud Sync background task expired")
        })
        Task {
            do { try await Store.shared.syncCloud() }
            catch { log("⚠️ Unable to sync: \(error.localizedDescription)") }
            await MainActor.run {
                self.logBackgroundTimeRemaining()
                log("iCloud background task ended")
                application.endBackgroundTask(cloudTask)
            }
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        log("Will enter foreground")
        
        // save energy
        guard ProcessInfo.processInfo.isLowPowerModeEnabled == false else { return }
        
        Task {
            // attempt to scan for all known locks if they are not in central cache
            if await Store.shared.central.state == .poweredOn {
                let locks = Store.shared.applicationData.locks.keys
                for lock in locks {
                    guard let peripheral = try? await Store.shared.device(for: lock) else {
                        continue
                    }
                    guard Store.shared.lockInformation[peripheral] == nil
                        else { continue }
                    do { try await Store.shared.readInformation(for: peripheral) }
                    catch { log("⚠️ Unable to read information: \(error.localizedDescription)") }
                }
            }
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        log("Did become active")
        
        didBecomeActive = true
        application.applicationIconBadgeNumber = 0
                        
        // scan for iBeacons
        //BeaconController.shared.scanBeacons()
        
        // save energy
        guard ProcessInfo.processInfo.isLowPowerModeEnabled == false else { return }
        
        // attempt to sync with iCloud
        //tabBarController.syncCloud()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        log("Will terminate")
        
        // scan for iBeacons
        //BeaconController.shared.scanBeacons()
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        Task {
            let result = await applicationPerformFetch(application)
            completionHandler(result)
        }
    }
    
    private func applicationPerformFetch(_ application: UIApplication) async -> UIBackgroundFetchResult {
        
        log("Perform background fetch")
        logBackgroundTimeRemaining()
        defer { log("Background fetch ended") }
        
        //BeaconController.shared.scanBeacons()
        
        //let lockInformation = Array(Store.shared.lockInformation.values)
        
        // 30 sec max background fetch
        let scanTask = Task { () -> UIBackgroundFetchResult in
            do {
                // scan for locks
                try await Store.shared.scan(duration: 3.0)
                // make sure each stored lock is visible
                let locks = Store.shared.applicationData.locks
                    .lazy
                    .sorted { $0.value.key.created < $1.value.key.created }
                    .map { $0.key }
                    .prefix(10)
                // scan for locks not found
                for lock in locks {
                    let _ = try await Store.shared.device(for: lock, scanDuration: 1.0)
                }
                return .newData
            } catch {
                log("⚠️ Unable to scan: \(error.localizedDescription)")
                return .failed
            }
        }
        
        let cloudTask = Task { () -> UIBackgroundFetchResult in
            do {
                guard try await Store.shared.cloud.accountStatus() == .available else {
                    return .noData
                }
                try await Store.shared.syncCloud()
                return .newData
            }
            catch {
                log("⚠️ Unable to sync: \(error.localizedDescription)")
                return .failed
            }
        }
        
        await MainActor.run {
            self.logBackgroundTimeRemaining()
        }
        
        async let results = [
            scanTask.value,
            cloudTask.value
        ]
        
        if await results.contains(.failed) {
            return .failed
        } else if await results.contains(.newData) {
            return .newData
        } else {
            return .noData
        }
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
        let timeString = Self.intervalFormatter.string(from: start, to: start + backgroundTimeRemaining)
        log("Background time remaining: \(timeString)")
    }
}

#elseif os(macOS)
final class AppDelegate: NSResponder, NSApplicationDelegate {
    
    // MARK: - NSApplicationDelegate
        
    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        return false
    }
}
#endif
