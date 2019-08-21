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

public final class BeaconController {
    
    public static let shared = BeaconController()
    
    private init() { }
    
    public var log: ((String) -> ())?
    
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = locationManagerDelegate
        locationManager.allowsBackgroundLocationUpdates = true
        return locationManager
    }()
    
    private lazy var locationManagerDelegate = LocationManagerDelegate(self)
    
    public private(set) var lockBeacons = [UUID: CLBeaconRegion]()
    
    public func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    public func monitor(lock identifier: UUID) {
        
        let region = CLBeaconRegion(proximityUUID: identifier, major: 0, minor: 0, identifier: identifier.uuidString)
        region.notifyEntryStateOnDisplay = true
        lockBeacons[identifier] = region
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways,
             .authorizedWhenInUse:
            locationManager.startMonitoring(for: region)
        case .denied,
             .notDetermined,
             .restricted:
            return
        }
    }
    
    @discardableResult
    public func stopMonitoring(lock identifier: UUID) -> Bool {
        
        guard let region = lockBeacons[identifier]
            else { return false }
        
        lockBeacons[identifier] = nil
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways,
             .authorizedWhenInUse:
            locationManager.stopMonitoring(for: region)
        case .denied,
             .notDetermined,
             .restricted:
            break
        }
        
        return true
    }
}

private extension BeaconController {
    
    @objc final class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
        
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
                beaconController?.lockBeacons.values.forEach {
                    beaconController?.locationManager.startMonitoring(for: $0)
                }
            case .denied,
                 .notDetermined,
                 .restricted:
                break
            }
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
            
            log("Started monitoring for \(region)")
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
            
            log("Monitoring failed for \(region?.description ?? ""). (\(error))")
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
            
            log("Entered region \(region)")
            
            if let beaconRegion = region as? CLBeaconRegion {
                
                manager.startRangingBeacons(in: beaconRegion)
            }
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
            
            log("Exited iBeacon region \(region)")
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
            
            log("Determined state \(state.debugDescription) for region \(region)")
            
            if let beaconRegion = region as? CLBeaconRegion {
                
                manager.startRangingBeacons(in: beaconRegion)
            }
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
            
            log("Found beacons \(beacons as NSArray) for region \(region.proximityUUID)")
            
            
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

extension BeaconController {
    
    
}
