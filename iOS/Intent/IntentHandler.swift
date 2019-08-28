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
        
        DispatchQueue.main.sync {
            
            let _  = IntentHandler.didLaunch
            LockManager.shared.log = { log("🔒 LockManager: " + $0) }
            #if os(iOS)
            BeaconController.shared.log = { log("📶 \(BeaconController.self): " + $0) }
            #endif
        }
        
        // load updated lock information
        Store.shared.loadCache()
        
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
    
    func confirm(intent: UnlockIntent, completion: @escaping (UnlockIntentResponse) -> Void) {
        
        mainQueue {
            
            guard let identifierString = intent.lock?.identifier,
                let lockIdentifier = UUID(uuidString: identifierString),
                let _ = Store.shared[lock: lockIdentifier] else {
                    completion(.failure(failureReason: "Invalid lock."))
                    return
            }
            
            completion(.init(code: .ready, userActivity: NSUserActivity(.action(.unlock(lockIdentifier)))))
        }
    }
    
    func handle(intent: UnlockIntent, completion: @escaping (UnlockIntentResponse) -> Void) {
        
        assert(Thread.isMainThread == false, "Not main thread")
        
        mainQueue {
            
            guard let identifierString = intent.lock?.identifier,
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
            
            async {
                do {
                    guard let peripheral = try Store.shared.device(for: lockIdentifier, scanDuration: 1.0) else {
                        completion(.failure(failureReason: "Lock not in range. "))
                        return
                    }
                    
                    guard try Store.shared.unlock(peripheral) else {
                        completion(.failure(failureReason: "Invalid lock."))
                        return
                    }
                    
                    completion(.success(lock: lockCache.name))
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
