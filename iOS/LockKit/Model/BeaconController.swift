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

/// iBeacon Controller
public final class BeaconController {
    
    // MARK: - Initialiation
    
    public static let shared = BeaconController()
    
    private init() { }
    
    // MARK: - Properties
    
    public var log: ((String) -> ())?
    
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = delegate
        return locationManager
    }()
    
    private lazy var delegate = Delegate(self)
    
    public private(set) var locks = [UUID: CLBeaconRegion]()
    
    public var allowsBackgroundLocationUpdates: Bool {
        get { return locationManager.allowsBackgroundLocationUpdates }
        set { locationManager.allowsBackgroundLocationUpdates = newValue }
    }
    
    public var foundLock: ((UUID, CLBeacon) -> ())?
    
    public var lostLock: ((UUID) -> ())?
    
    private var foundBeacons = [UUID: CLBeacon]()
    
    // MARK: - Methods
    
    public func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    public func monitor(lock identifier: UUID) {
        
        let region: CLBeaconRegion
        if #available(iOS 13.0, iOSApplicationExtension 13.0, *) {
            region = CLBeaconRegion(uuid: identifier, identifier: identifier.uuidString)
        } else {
            region = CLBeaconRegion(proximityUUID: identifier, identifier: identifier.uuidString)
        }
        region.notifyOnEntry = true
        region.notifyEntryStateOnDisplay = true
        region.notifyOnExit = true
        locks[identifier] = region
        
        // initiate monitoring and scanning
        scanBeacons(in: region)
    }
    
    @discardableResult
    public func stopMonitoring(lock identifier: UUID) -> Bool {
        
        guard let region = locks[identifier]
            else { return false }
        
        locks[identifier] = nil
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            locationManager.stopMonitoring(for: region)
            #if !targetEnvironment(macCatalyst)
            locationManager.stopRangingBeacons(in: region)
            #endif
        case .authorizedWhenInUse:
            #if !targetEnvironment(macCatalyst)
            locationManager.stopRangingBeacons(in: region)
            #endif
        case .denied,
             .notDetermined,
             .restricted:
            break
        @unknown default:
            break
        }
        
        return true
    }
    
    public func scanBeacons() {
        locks.values.forEach { scanBeacons(in: $0) }
    }
    
    @discardableResult
    public func scanBeacon(for lock: UUID) -> Bool {
        guard let region = locks[lock]
            else { return false }
        scanBeacons(in: region)
        return true
    }
    
    private func scanBeacons(in region: CLBeaconRegion) {
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            #if !targetEnvironment(macCatalyst)
            if locationManager.monitoredRegions.contains(region) == false {
                locationManager.startMonitoring(for: region)
            }
            if locationManager.rangedRegions.contains(region) == false {
                locationManager.startRangingBeacons(in: region)
            }
            #endif
            locationManager.requestState(for: region)
        case .authorizedWhenInUse:
            #if !targetEnvironment(macCatalyst)
            if locationManager.rangedRegions.contains(region) == false {
                locationManager.startRangingBeacons(in: region)
            }
            #endif
            locationManager.requestState(for: region)
        case .denied,
             .notDetermined,
             .restricted:
            break
        @unknown default:
            // try just in case, ignore errors
            #if !targetEnvironment(macCatalyst)
            locationManager.startMonitoring(for: region)
            locationManager.startRangingBeacons(in: region)
            #endif
            locationManager.requestState(for: region)
        }
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
            
            beaconController?.scanBeacons()
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
                if let lock = beaconController?.locks.first(where: { $0.value == region })?.key {
                    // clear stale beacons
                    self.beaconController?.foundBeacons[lock] = nil
                }
                #if !targetEnvironment(macCatalyst)
                manager.startRangingBeacons(in: beaconRegion)
                #endif
            }
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
            
            log("Exited beacon region \(region.identifier)")
            
            if let beaconRegion = region as? CLBeaconRegion {
                #if !targetEnvironment(macCatalyst)
                if manager.rangedRegions.contains(beaconRegion) {
                     manager.stopRangingBeacons(in: beaconRegion)
                }
                #endif
                if let lock = beaconController?.locks.first(where: { $0.value == region })?.key {
                    defer { self.beaconController?.foundBeacons[lock] = nil }
                    let oldBeacon = self.beaconController?.foundBeacons[lock]
                    if oldBeacon != nil {
                        self.beaconController?.log?("Cannot find beacon for lock \(lock)")
                        self.beaconController?.lostLock?(lock)
                    }
                }
            }
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
            
            log("Determined state \(state.debugDescription) for region \(region.identifier)")
            
            if let beaconRegion = region as? CLBeaconRegion {
                
                switch state {
                case .inside:
                    #if targetEnvironment(macCatalyst)
                    
                    #else
                    manager.startRangingBeacons(in: beaconRegion)
                    #endif
                case .outside,
                     .unknown:
                    #if !targetEnvironment(macCatalyst)
                    manager.stopRangingBeacons(in: beaconRegion)
                    #endif
                    if let lock = beaconController?.locks.first(where: { $0.value == region })?.key {
                        defer { self.beaconController?.foundBeacons[lock] = nil }
                        let oldBeacon = self.beaconController?.foundBeacons[lock]
                        if oldBeacon != nil {
                            self.beaconController?.log?("Cannot find beacon for lock \(lock)")
                            self.beaconController?.lostLock?(lock)
                        }
                    }
                }
            }
        }
        
        #if !targetEnvironment(macCatalyst)
        @objc
        public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
            
            log("Found \(beacons.count) beacons for region \(region.identifier)")
            
            guard let beaconController = self.beaconController
                else { assertionFailure(); return }
            
            // is lock iBeacon, make sure the lock is scanned for BLE operations
            if let lock = beaconController.locks.first(where: { $0.value == region })?.key {
                
                assert(beacons.count <= 1, "Should only be one lock iBeacon")
                
                // stop BLE scanning for iBeacon
                manager.stopRangingBeacons(in: region)
                
                guard let beacon = beacons.first else {
                    // make sure we are inside the Beacon region
                    manager.requestState(for: region)
                    return
                }
                
                let oldBeacon = beaconController.foundBeacons[lock]
                beaconController.foundBeacons[lock] = beacon
                if oldBeacon == nil {
                    beaconController.log?("Found beacon for lock \(lock)")
                    beaconController.foundLock?(lock, beacon)
                }
            } else {
                manager.stopRangingBeacons(in: region)
            }
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
            
            log("Ranging beacons failed for region \(region). \(error)")
        }
        #endif
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
