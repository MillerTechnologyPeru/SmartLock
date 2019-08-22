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
import Bluetooth
import GATT
import DarwinGATT
import CoreLock
import LockKit

// As an example, this class is set up to handle Message intents.
// You will want to replace this or add other intents as appropriate.
// The intents you wish to handle must be declared in the extension's Info.plist.

// You can test your example integration by saying things to Siri like:
// "Send a message using <myApp>"
// "<myApp> John saying hello"
// "Search for messages in <myApp>"

final class IntentHandler: INExtension, INSendMessageIntentHandling, INSearchForMessagesIntentHandling, INSetMessageAttributeIntentHandling {
    
    static let didLaunch: Void = {
        // configure logging
        Log.shared = .intent
        // print app info
        log("📱 Launching Intent")
    }()
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        DispatchQueue.main.sync {
            
            let _  = IntentHandler.didLaunch
            LockManager.shared.log = { log("🔒 \(LockManager.self): " + $0) }
            BeaconController.shared.log = { log("📶 \(BeaconController.self): " + $0) }
        }
        
        return UnlockIntentHandler()
    }
    
    // MARK: - INSendMessageIntentHandling
    
    // Implement resolution methods to provide additional information about your intent (optional).
    func resolveRecipients(for intent: INSendMessageIntent, with completion: @escaping ([INSendMessageRecipientResolutionResult]) -> Void) {
        if let recipients = intent.recipients {
            
            // If no recipients were provided we'll need to prompt for a value.
            if recipients.count == 0 {
                completion([INSendMessageRecipientResolutionResult.needsValue()])
                return
            }
            
            var resolutionResults = [INSendMessageRecipientResolutionResult]()
            for recipient in recipients {
                let matchingContacts = [recipient] // Implement your contact matching logic here to create an array of matching contacts
                switch matchingContacts.count {
                case 2  ... Int.max:
                    // We need Siri's help to ask user to pick one from the matches.
                    resolutionResults += [INSendMessageRecipientResolutionResult.disambiguation(with: matchingContacts)]
                    
                case 1:
                    // We have exactly one matching contact
                    resolutionResults += [INSendMessageRecipientResolutionResult.success(with: recipient)]
                    
                case 0:
                    // We have no contacts matching the description provided
                    resolutionResults += [INSendMessageRecipientResolutionResult.unsupported()]
                    
                default:
                    break
                    
                }
            }
            completion(resolutionResults)
        }
    }
    
    func resolveContent(for intent: INSendMessageIntent, with completion: @escaping (INStringResolutionResult) -> Void) {
        if let text = intent.content, !text.isEmpty {
            completion(INStringResolutionResult.success(with: text))
        } else {
            completion(INStringResolutionResult.needsValue())
        }
    }
    
    // Once resolution is completed, perform validation on the intent and provide confirmation (optional).
    
    func confirm(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        // Verify user is authenticated and your app is ready to send a message.
        
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INSendMessageIntent.self))
        let response = INSendMessageIntentResponse(code: .ready, userActivity: userActivity)
        completion(response)
    }
    
    // Handle the completed intent (required).
    
    func handle(intent: INSendMessageIntent, completion: @escaping (INSendMessageIntentResponse) -> Void) {
        // Implement your application logic to send a message here.
        
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INSendMessageIntent.self))
        let response = INSendMessageIntentResponse(code: .success, userActivity: userActivity)
        completion(response)
    }
    
    // Implement handlers for each intent you wish to handle.  As an example for messages, you may wish to also handle searchForMessages and setMessageAttributes.
    
    // MARK: - INSearchForMessagesIntentHandling
    
    func handle(intent: INSearchForMessagesIntent, completion: @escaping (INSearchForMessagesIntentResponse) -> Void) {
        // Implement your application logic to find a message that matches the information in the intent.
        
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INSearchForMessagesIntent.self))
        let response = INSearchForMessagesIntentResponse(code: .success, userActivity: userActivity)
        // Initialize with found message's attributes
        response.messages = [INMessage(
            identifier: "identifier",
            content: "I am so excited about SiriKit!",
            dateSent: Date(),
            sender: INPerson(personHandle: INPersonHandle(value: "sarah@example.com", type: .emailAddress), nameComponents: nil, displayName: "Sarah", image: nil,  contactIdentifier: nil, customIdentifier: nil),
            recipients: [INPerson(personHandle: INPersonHandle(value: "+1-415-555-5555", type: .phoneNumber), nameComponents: nil, displayName: "John", image: nil,  contactIdentifier: nil, customIdentifier: nil)]
            )]
        completion(response)
    }
    
    // MARK: - INSetMessageAttributeIntentHandling
    
    func handle(intent: INSetMessageAttributeIntent, completion: @escaping (INSetMessageAttributeIntentResponse) -> Void) {
        // Implement your application logic to set the message attribute here.
        
        let userActivity = NSUserActivity(activityType: NSStringFromClass(INSetMessageAttributeIntent.self))
        let response = INSetMessageAttributeIntentResponse(code: .success, userActivity: userActivity)
        completion(response)
    }
}

// MARK: - UnlockIntentHandler

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

extension Log {
    
    static var intent: Log {
        struct Cache {
            static let log: Log = {
                do { return try Log.Store.caches.create(date: Date(), bundle: .init(for: IntentHandler.self)) }
                catch { assertionFailure("Could not create log file: \(error)"); return .appCache }
            }()
        }
        return Cache.log
    }
}
