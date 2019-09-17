//
//  IntentHandler.swift
//  Intent
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import Intents
import CoreBluetooth
import CoreLock
import Bluetooth
import GATT
import DarwinGATT
import LockKit

final class IntentHandler: INExtension {
    
    static let didLaunch: Void = {
        // configure logging
        #if os(iOS)
        Log.shared = .intent
        #endif
        // print app info
        log("🎙 Launching Intent")
    }()
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        assert(Thread.isMainThread == false)
        DispatchQueue.main.sync {
            let _  = IntentHandler.didLaunch
            LockManager.shared.log = { log("🔒 LockManager: " + $0) }
            #if os(iOS)
            BeaconController.shared.log = { log("📶 \(BeaconController.self): " + $0) }
            #endif
            // load updated lock information
            Store.shared.loadCache()
        }
        
        if #available(watchOSApplicationExtension 5.0, *) {
            return UnlockIntentHandler()
        } else {
            fatalError()
        }
    }
}

// MARK: - UnlockIntentHandler

@available(watchOSApplicationExtension 5.0, *)
final class UnlockIntentHandler: NSObject, UnlockIntentHandling {
    
    @available(iOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
    func provideLockOptions(for intent: UnlockIntent, with completion: @escaping ([IntentLock]?, Error?) -> Void) {
        
        DispatchQueue.app.async {
            // load updated lock information
            Store.shared.loadCache()
            
            // locks
            let intentLocks = Store.shared.locks.value.map { IntentLock(identifier: $0, name: $1.name) }
            completion(intentLocks, nil)
        }
    }
    
    @available(iOSApplicationExtension 13.0, watchOSApplicationExtension 6.0, *)
    func resolveLock(for intent: UnlockIntent, with completion: @escaping (UnlockLockResolutionResult) -> Void) {
        
        DispatchQueue.bluetooth.async {
            
            // load updated lock information
            Store.shared.loadCache()
            
            // a specified lock is required to complete the action
            guard let intentLock = intent.lock else {
                completion(.needsValue())
                return
            }
                        
            // validate UUID string
            guard let identifier = intentLock.identifier.flatMap({ UUID(uuidString: $0) }) else {
                completion(.unsupported())
                return
            }
            
            // validate key is available for lock.
            guard let lockCache = Store.shared[lock: identifier],
                Store.shared[key: lockCache.key.identifier] != nil else {
                    completion(.unsupported(forReason: .unknownLock))
                    return
            }
            
            // check if lock is in range
            var device: LockPeripheral<NativeCentral>?
            do { device = try Store.shared.device(for: identifier, scanDuration: 2.0) }
            catch {
                completion(.confirmationRequired(with: intentLock))
                return
            }
            
            // device not in range
            guard let _ = device else {
                completion(.confirmationRequired(with: intentLock))
                return
            }
            
            completion(.success(with: intentLock))
        }
    }
    
    func confirm(intent: UnlockIntent, completion: @escaping (UnlockIntentResponse) -> Void) {
        
        assert(Thread.isMainThread == false, "Should not be main thread")
        
        mainQueue {
            
            guard let intentLock = intent.lock else {
                completion(.failure(failureReason: "No lock specified."))
                return
            }
            
            guard let identifierString = intentLock.identifier,
                let lockIdentifier = UUID(uuidString: identifierString),
                let _ = Store.shared[lock: lockIdentifier] else {
                    completion(.failure(failureReason: "Invalid lock."))
                    return
            }
            
            completion(.init(code: .ready, userActivity: NSUserActivity(.action(.unlock(lockIdentifier)))))
        }
    }
    
    func handle(intent: UnlockIntent, completion: @escaping (UnlockIntentResponse) -> Void) {
        
        assert(Thread.isMainThread == false, "Should not be main thread")
        
        mainQueue {
            
            guard let intentLock = intent.lock else {
                completion(.failure(failureReason: "No lock specified."))
                return
            }
            
            guard let identifierString = intentLock.identifier,
                let lockIdentifier = UUID(uuidString: identifierString),
                let lockCache = Store.shared[lock: lockIdentifier] else {
                    completion(.failure(failureReason: "Invalid lock."))
                    return
            }
            
            // validate schedule
            if case let .scheduled(schedule) = lockCache.key.permission {
                guard schedule.isValid() else {
                    completion(.failure(failureReason: "Can only use key during schedule."))
                    return
                }
            }
            
            DispatchQueue.bluetooth.async {
                do {
                    guard let peripheral = try Store.shared.device(for: lockIdentifier, scanDuration: 1.0) else {
                        completion(.failure(failureReason: "Lock not in range. "))
                        return
                    }
                    
                    guard try Store.shared.unlock(peripheral) else {
                        completion(.failure(failureReason: "Invalid lock."))
                        return
                    }
                    
                    completion(.success(lock: intentLock))
                }
                catch {
                    completion(.failure(failureReason: error.localizedDescription))
                    return
                }
            }
        }
    }
}

// MARK: - Logging

#if os(iOS)
extension Log {
    
    static var intent: Log {
        struct Cache {
            static let log: Log = {
                do { return try Log.Store.lockAppGroup.create(date: Date(), bundle: .init(for: IntentHandler.self)) }
                catch { assertionFailure("Could not create log file: \(error)"); return .appCache }
            }()
        }
        return Cache.log
    }
}
#endif
