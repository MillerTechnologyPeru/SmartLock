//
//  SessionController.swift
//  LockKit watchOS
//
//  Created by Alsey Coleman Miller on 8/28/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import WatchConnectivity
import CoreLock

public final class SessionController: NSObject {
    
    public static let shared = SessionController()
    
    // MARK: - Properties
    
    public var timeout: TimeInterval = 15.0
    
    public var log: ((String) -> ())?
    
    internal let session: WCSession = .default
    
    public var context: ((WatchApplicationContext) -> ())?

    public var activationState: WCSessionActivationState {
        return session.activationState
    }
    
    public var isReachable: Bool {
        guard session.activationState == .activated
            else { return false }
        return session.isReachable
    }
    
    private var operationState: (semaphore: DispatchSemaphore, error: Swift.Error?)?
    
    private var lastMessage: [String: Any]?
    
    // MARK: - Mehods
    
    /// Activates the session synchronously.
    public func activate() throws {
        
        assert(Thread.isMainThread == false, "Do not call from main thread")
        
        guard session.activationState != .activated
            else { return }
        
        log?("Request session activation")
        
        session.delegate = self
        session.activate()
        
        // wait
        try wait()
    }
    
    public func requestApplicationData() throws -> ApplicationData {
        
        let response = try request(.applicationData)
        switch response {
        case let .error(error):
            throw Error.errorResponse(error)
        case let .applicationData(applicationData):
            return applicationData
        case .key:
            throw Error.invalidResponse
        }
    }
    
    public func requestKeyData(for identifier: UUID) throws -> KeyData {
        
        let response = try request(.applicationData)
        switch response {
        case let .error(error):
            throw Error.errorResponse(error)
        case let .key(keyData):
            return keyData
        case .applicationData:
            throw Error.invalidResponse
        }
    }
    
    private func request(_ request: WatchMessage.Request) throws -> WatchMessage.Response {
        
        // activate if not already activated
        try activate()
        
        guard session.isReachable
            else { throw Error.notReachable }
                
        log?("Will request \(request)")
        
        let requestMessage = WatchMessage.request(request).toMessage()
        
        let semaphore = DispatchSemaphore(value: 0)
        var error: Swift.Error?
        var reply: [String: Any]?
        session.sendMessage(requestMessage, replyHandler: {
            reply = $0
            semaphore.signal()
        }, errorHandler: {
            error = $0
            semaphore.signal()
        })
        if semaphore.wait(timeout: .now() + timeout) == .timedOut {
            throw Error.timeout
        }
        if let error = error {
            throw error
        }
        guard let message = reply
            else { throw Error.timeout }
        guard let replyMessage = WatchMessage(message: message)
            else { throw Error.invalidResponse }
        switch replyMessage {
        case let .response(response):
            return response
        case .request:
            throw Error.invalidResponse
        }
    }
    
    private func wait() throws {
        
        assert(operationState == nil, "Already waiting for an asyncronous operation to finish")
        
        let semaphore = DispatchSemaphore(value: 0)
        operationState = (semaphore, nil)
        let dispatchTime: DispatchTime = .now() + Double(timeout)
        let waitResult = semaphore.wait(timeout: dispatchTime)
        let error = operationState?.error
        operationState = nil
        if let error = error {
            throw error
        }
        if waitResult == .timedOut {
            throw Error.timeout
        }
    }
    
    private func stopWaiting(_ error: Swift.Error? = nil, _ function: String = #function) {
        
        assert(operationState != nil, "Did not expect \(function)")
        operationState?.error = error
        operationState?.semaphore.signal()
    }
    
    /// Have to move these here due to compiler bug.
    @objc(sessionDidBecomeInactive:)
    public func sessionDidBecomeInactive(_ session: WCSession) {
        
        log?("Session did become inactive")
    }
    
    @objc(sessionDidDeactivate:)
    public func sessionDidDeactivate(_ session: WCSession) {
        
        log?("Session did deactivate")
    }
}

// MARK: - WCSessionDelegate

extension SessionController: WCSessionDelegate {
    
    @objc @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Swift.Error?) {
        
        if let error = error {
            log?("Activation did not complete: " + error.localizedDescription)
            #if DEBUG
            dump(error)
            #endif
        } else {
            log?(activationState.debugDescription)
        }
        
        log?("Session reachable: \(isReachable)")
        
        stopWaiting(error)
    }
    
    @objc(sessionReachabilityDidChange:)
    public func sessionReachabilityDidChange(_ session: WCSession) {
        
        log?("Session reachable: \(session.isReachable)")
    }
    
    @objc
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        log?("Recieved message: \(message)")
        lastMessage = message
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        
        log?("Received application context \(applicationContext)")
        
        guard let context = WatchApplicationContext(message: applicationContext) else {
            log?("⚠️ Invalid application context")
            return
        }
        
        #if DEBUG
        dump(context)
        #endif
        
        self.context?(context)
    }
}

// MARK: - Supporting Types

public extension SessionController {
    
    enum Error: Swift.Error {
        
        case timeout
        case notReachable
        case notActivated
        case errorResponse(String)
        case invalidResponse
    }
}

private extension WCSessionActivationState {
    
    var debugDescription: String {
        
        switch self {
        case .notActivated:
            return "Not Activated"
        case .inactive:
            return "Inactive"
        case .activated:
             return "Activated"
        @unknown default:
            return "Activation State \(rawValue)"
        }
    }
}

// MARK: - Sync

public extension Store {
    
    func syncApp(session: SessionController = .shared,
                 completion: (() -> ())? = nil) {
        
        // activate session
        async { [weak self] in
            defer { Store.shared.defaults.lastWatchUpdate = Date() }
            defer { mainQueue { completion?() } }
            guard let self = self else { return }
            do { try session.activate() }
            catch { log("⚠️ Unable to activate session \(error)") }
            do {
                let newData = try session.requestApplicationData()
                let oldApplicationData = self.applicationData
                guard newData != oldApplicationData else {
                    log("📱 No new data")
                    return
                }
                #if DEBUG
                print("📱 Recieved new application data")
                dump(newData)
                #endif
                var importedKeys = 0
                for key in newData.keys {
                    if self[key: key.identifier] == nil {
                        let keyData = try session.requestKeyData(for: key.identifier)
                        self[key: key.identifier] = keyData
                        importedKeys += 1
                    }
                }
                if importedKeys > 0 {
                    log("📱 Imported \(importedKeys) keys")
                }
                // write new data
                self.applicationData = newData
                log("📱 Updated application data")
                // remove old keys
                var removedKeys = 0
                for oldKey in oldApplicationData.keys {
                    // old key no longer exists
                    if newData.keys.contains(oldKey) == false {
                        // remove from keychain
                        self[key: oldKey.identifier] = nil
                        removedKeys += 1
                    }
                }
                if removedKeys > 0 {
                    log("📱 Removed \(removedKeys) old keys from keychain")
                }
            } catch {
                log("⚠️ Unable to sync application data \(error)")
            }
        }
    }
}
