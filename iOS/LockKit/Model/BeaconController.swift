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
    
    public private(set) var beacons = [UUID: Beacon]()
    
    public var allowsBackgroundLocationUpdates: Bool {
        get { return locationManager.allowsBackgroundLocationUpdates }
        set { locationManager.allowsBackgroundLocationUpdates = newValue }
    }
    
    public var beaconChanged: ((Beacon) -> ())?
    
    // MARK: - Methods
    
    public func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    public func monitor(_ beacon: UUID) {
        
        let uuid = beacon
        let beacon = Beacon(uuid: uuid)
        beacon.didChange = { [weak self] in self?.beaconChanged?(beacon) }
        beacons[uuid] = beacon
        
        // initiate monitoring and scanning
        scanBeacons(in: beacon.region)
    }
    
    @discardableResult
    public func stopMonitoring(_ beacon: UUID) -> Bool {
        
        guard let region = beacons[beacon]?.region
            else { return false }
        
        beacons[beacon] = nil
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            locationManager.stopMonitoring(for: region)
            locationManager.stopRangingBeacons(in: beacon)
        case .authorizedWhenInUse:
            locationManager.stopRangingBeacons(in: beacon)
        case .denied,
             .notDetermined,
             .restricted:
            break
        @unknown default:
            locationManager.stopRangingBeacons(in: beacon)
        }
        
        return true
    }
    
    public func scanBeacons() {
        beacons.values.forEach { scanBeacons(in: $0.region) }
    }
    
    @discardableResult
    public func scanBeacon(for identifier: UUID) -> Bool {
        guard let region = beacons[identifier]?.region
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
            #endif
            if #available(iOS 13, *) {
                if locationManager.rangedBeaconConstraints.contains(.init(region)) == false {
                    locationManager.startRangingBeacons(satisfying: .init(region))
                }
            } else {
                #if !targetEnvironment(macCatalyst)
                if locationManager.rangedRegions.contains(region) == false {
                    locationManager.startRangingBeacons(in: region)
                }
                #endif
            }
            locationManager.requestState(for: region)
        case .authorizedWhenInUse:
            if #available(iOS 13, *) {
                if locationManager.rangedBeaconConstraints.contains(.init(region)) == false {
                    locationManager.startRangingBeacons(satisfying: .init(region))
                }
            } else {
                #if !targetEnvironment(macCatalyst)
                if locationManager.rangedRegions.contains(region) == false {
                    locationManager.startRangingBeacons(in: region)
                }
                #endif
            }
            locationManager.requestState(for: region)
        case .denied,
             .notDetermined,
             .restricted:
            break
        @unknown default:
            // try just in case, ignore errors
            locationManager.requestState(for: region)
            locationManager.startMonitoring(for: region)
            if #available(iOS 13, *) {
                if locationManager.rangedBeaconConstraints.contains(.init(region)) == false {
                    locationManager.startRangingBeacons(satisfying: .init(region))
                }
            } else {
                #if !targetEnvironment(macCatalyst)
                if locationManager.rangedRegions.contains(region) == false {
                    locationManager.startRangingBeacons(in: region)
                }
                #endif
            }
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
            
            guard let beaconController = self.beaconController
                else { assertionFailure(); return }
            
            if let beaconRegion = region as? CLBeaconRegion {
                
                // start ranging beacons
                if #available(iOS 13, *) {
                    if manager.rangedBeaconConstraints.contains(.init(beaconRegion)) == false {
                        manager.startRangingBeacons(satisfying: .init(beaconRegion))
                    }
                } else {
                    #if !targetEnvironment(macCatalyst)
                    if manager.rangedRegions.contains(region) == false {
                        manager.startRangingBeacons(in: beaconRegion.proximityUUID)
                    }
                    #endif
                }
                
                guard let beacon = beaconController.beacons.first(where: { $0.value.region == region })?.value
                    else { assertionFailure("Invalid beacon \(beaconRegion.proximityUUID)"); return }
                
                // update state
                beacon.state = .inside
            }
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
            
            log("Exited beacon region \(region.identifier)")
            
            guard let beaconController = self.beaconController
                else { assertionFailure(); return }
            
            if let beaconRegion = region as? CLBeaconRegion {
                // stop ranging beacons
                if #available(iOS 13, *) {
                    if manager.rangedBeaconConstraints.contains(.init(beaconRegion)) {
                        manager.stopRangingBeacons(satisfying: .init(beaconRegion))
                    }
                } else {
                    #if !targetEnvironment(macCatalyst)
                    if manager.rangedRegions.contains(beaconRegion) {
                         manager.stopRangingBeacons(in: beaconRegion)
                    }
                    #endif
                }
                
                guard let beacon = beaconController.beacons.first(where: { $0.value.region == region })?.value
                    else { return }
                
                // update state
                beacon.state = .outside
            }
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
            
            log("Determined state \(state.debugDescription) for region \(region.identifier)")
            
            if let beaconRegion = region as? CLBeaconRegion {
                
                let newState: Beacon.State
                switch state {
                case .unknown:
                    // start ranging beacons
                    manager.startRangingBeacons(in: beaconRegion.proximityUUID)
                    newState = .outside
                case .inside:
                    // start ranging beacons
                    manager.startRangingBeacons(in: beaconRegion.proximityUUID)
                    newState = .inside
                case .outside:
                    // stop ranging beacons
                    manager.stopRangingBeacons(in: beaconRegion.proximityUUID)
                    newState = .outside
                }
                
                guard let beacon = beaconController?.beacons.first(where: { $0.value.region == region })?.value
                    else { return }
                
                beacon.state = newState
            }
        }
        
        private func didRange(beacons: [CLBeacon], for uuid: UUID) {
            
            log("Found \(beacons.count) beacons for region \(uuid)")
            
            guard let beaconController = self.beaconController
                else { assertionFailure(); return }
            
            let manager = beaconController.locationManager
            
            guard let beacon = beaconController.beacons[uuid] else {
                manager.stopRangingBeacons(in: uuid)
                assertionFailure("Invalid beacon \(uuid)")
                return
            }
            
            guard beacons.isEmpty == false else {
                // make sure we are inside the Beacon region
                manager.requestState(for: uuid)
                return
            }
            
            // set state
            beacon.state = .inside
            
            // stop BLE scanning for iBeacon
            manager.stopRangingBeacons(in: uuid)
        }
        
        @available(iOSApplicationExtension 13.0, *)
        @objc
        public func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
            
            didRange(beacons: beacons, for: beaconConstraint.uuid)
        }
        
        @available(iOSApplicationExtension 13.0, *)
        @objc
        public func locationManager(_ manager: CLLocationManager, didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint, error: Error) {
                        
            log("Ranging beacons failed for \(beaconConstraint.uuid). \(error)")
        }
        
        #if !targetEnvironment(macCatalyst)
        @objc
        public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
            
            didRange(beacons: beacons, for: region.proximityUUID)
        }
        
        @objc
        public func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
            
            log("Ranging beacons failed for \(region.identifier). \(error)")
        }
        #endif
    }
}

// MARK: - Supporting Types

public extension BeaconController {
    
    final class Beacon {
        
        public let uuid: UUID
        public fileprivate(set) var state: State = .outside {
            didSet { if state != oldValue { didChange() } }
        }
        internal let region: CLBeaconRegion
        internal fileprivate(set) var didChange: (() -> ()) = { }
        
        init(uuid: UUID) {
            self.uuid = uuid
            self.region = CLBeaconRegion(uuid: uuid)
            region.notifyOnEntry = true
            region.notifyEntryStateOnDisplay = true
            region.notifyOnExit = true
        }
    }
}

public extension BeaconController.Beacon {
    
    enum State: Equatable, Hashable {
        case inside
        case outside
    }
}

// MARK: - CoreLocation Extensions

internal extension CLLocationManager {
    
    func requestState(for uuid: UUID) {
        requestState(for: CLBeaconRegion(uuid: uuid))
    }
    
    func startRangingBeacons(in uuid: UUID) {
        if #available(iOS 13, iOSApplicationExtension 13.0, *) {
            startRangingBeacons(satisfying: .init(uuid: uuid))
        } else {
            #if !targetEnvironment(macCatalyst)
            startRangingBeacons(in: CLBeaconRegion(proximityUUID: uuid, identifier: uuid.uuidString))
            #endif
        }
    }
    
    func stopRangingBeacons(in uuid: UUID) {
        if #available(iOS 13, iOSApplicationExtension 13.0, *) {
            stopRangingBeacons(satisfying: .init(uuid: uuid))
        } else {
            #if !targetEnvironment(macCatalyst)
            stopRangingBeacons(in: CLBeaconRegion(proximityUUID: uuid, identifier: uuid.uuidString))
            #endif
        }
    }
}

internal extension CLBeaconRegion {
    
    convenience init(uuid identifier: UUID) {
        if #available(iOS 13.0, iOSApplicationExtension 13.0, *) {
            self.init(beaconIdentityConstraint: .init(uuid: identifier), identifier: identifier.uuidString)
        } else {
            self.init(proximityUUID: identifier, identifier: identifier.uuidString)
        }
    }
}

@available(iOS 13, iOSApplicationExtension 13.0, *)
internal extension CLBeaconIdentityConstraint {
    
    convenience init(_ region: CLBeaconRegion) {
        self.init(uuid: region.uuid)
    }
}

internal extension CLAuthorizationStatus {
    
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

internal extension CLRegionState {
    
    var debugDescription: String {
        switch self {
        case .inside: return "inside"
        case .outside: return "outside"
        case .unknown: return "unknown"
        }
    }
}
