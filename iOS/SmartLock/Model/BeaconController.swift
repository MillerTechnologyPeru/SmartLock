//
//  iBeaconManager.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/20/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock
import CoreLocation
import UIKit

public final class BeaconController {
    
    public static let shared = BeaconController()
    
    private init() { }
    
    public var log: ((String) -> ())?
    
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = delegate
        locationManager.allowsBackgroundLocationUpdates = true
        return locationManager
    }()
    
    private lazy var delegate = Delegate(self)
    
    public private(set) var locks = [UUID: CLBeaconRegion]()
    
    public func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    public func monitor(lock identifier: UUID) {
        
        let region = CLBeaconRegion(proximityUUID: identifier, major: 0, minor: 0, identifier: identifier.uuidString)
        region.notifyOnEntry = true
        region.notifyEntryStateOnDisplay = true
        region.notifyOnExit = true
        locks[identifier] = region
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways,
             .authorizedWhenInUse:
            locationManager.startMonitoring(for: region)
        case .denied,
             .notDetermined,
             .restricted:
            break
        @unknown default:
            break
        }
    }
    
    @discardableResult
    public func stopMonitoring(lock identifier: UUID) -> Bool {
        
        guard let region = locks[identifier]
            else { return false }
        
        locks[identifier] = nil
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways,
             .authorizedWhenInUse:
            locationManager.stopMonitoring(for: region)
        case .denied,
             .notDetermined,
             .restricted:
            break
        @unknown default:
            break
        }
        
        return true
    }
}

private extension BeaconController {
    
    @objc(BeaconControllerDelegate)
    final class Delegate: NSObject, CLLocationManagerDelegate {
        
        init(_ beaconController: BeaconController) {
            self.beaconController = beaconController
        }
        
        private(set) weak var beaconController: BeaconController?
        
        private func log(_ message: String) {
            beaconController?.log?(message)
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            
            log("Changed authorization (\(status.debugDescription))")
            
            switch status {
            case .authorizedAlways,
                 .authorizedWhenInUse:
                beaconController?.locks.values.forEach {
                    manager.startMonitoring(for: $0)
                }
            case .denied,
                 .notDetermined,
                 .restricted:
                break
            @unknown default:
                return
            }
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
            
            log("Started monitoring for \(region.identifier)")
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
            
            log("Monitoring failed for \(region?.description ?? ""). (\(error))")
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
            
            log("Entered region \(region.identifier)")
            
            if let beaconRegion = region as? CLBeaconRegion {
                manager.startRangingBeacons(in: beaconRegion)
            }
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
            
            log("Exited iBeacon region \(region.identifier)")
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
            
            log("Determined state \(state.debugDescription) for region \(region.identifier)")
            
            if let beaconRegion = region as? CLBeaconRegion {
                
                switch state {
                case .inside:
                    manager.startRangingBeacons(in: beaconRegion)
                case .outside,
                     .unknown:
                    if let lock = beaconController?.locks.first(where: { $0.value == region })?.key {
                        if #available(iOS 10.0, *) {
                            UserNotificationCenter.shared.removeUnlockNotification(for: lock)
                        }
                    }
                }
            }
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
            
            log("Found \(beacons.count) beacons for region \(region.identifier)")
            
            guard let beaconController = self.beaconController
                else { assertionFailure(); return }
            
            // is lock iBeacon, make sure the lock is scanned for BLE operations
            if let lock = beaconController.locks.first(where: { $0.value == region })?.key {
                
                assert(beacons.count <= 1, "Should only be one lock iBeacon")
                manager.stopRangingBeacons(in: region)
                
                async { [weak self] in
                    guard let self = self else { return }
                    do {
                        self.log("Found beacon for lock \(lock)")
                        guard let _ = try Store.shared.device(for: lock, scanDuration: 1) else {
                            self.log("Could not find lock \(lock)")
                            manager.requestState(for: region)
                            return
                        }
                        if #available(iOS 10, *),
                            let lockCache = Store.shared[lock: lock] {
                            // show unlock notification
                            UserNotificationCenter.shared.postUnlockNotification(for: lock, name: lockCache.name)
                        }
                    } catch {
                        self.log("Error: \(error)")
                    }
                }
            } else {
                manager.stopRangingBeacons(in: region)
            }
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
            
            log("Ranging beacons failed for region \(region). \(error)")
        }
    }
}

private extension CLAuthorizationStatus {
    
    var debugDescription: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedWhenInUse: return "Authorized When in use"
        case .authorizedAlways: return "Always Authorized"
        @unknown default:
            return "Status \(rawValue)"
        }
    }
}

private extension CLRegionState {
    
    var debugDescription: String {
        switch self {
        case .inside: return "inside"
        case .outside: return "outside"
        case .unknown: return "unknown"
        }
    }
}
