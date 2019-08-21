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

final class BeaconController: NSObject {
    
    static let shared = BeaconController()
    
    private override init() { }
    
    var log: ((String) -> ())?
    
    private lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        return locationManager
    }()
    
    private var lockBeacons = [UUID: CLBeaconRegion]()
    
    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    
}

extension BeaconController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        
        if let beaconRegion = region as? CLBeaconRegion {
            log?("Started iBeacon monitoring for \(beaconRegion)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        
        log?("Monitoring failed for \(region?.description ?? ""). (\(error))")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        if let beaconRegion = region as? CLBeaconRegion {
            log?("Entered iBeacon region \(beaconRegion)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        
        if let beaconRegion = region as? CLBeaconRegion {
            log?("Exited iBeacon region \(beaconRegion)")
        }
    }
}
