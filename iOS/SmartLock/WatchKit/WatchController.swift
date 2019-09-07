//
//  WatchController.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/28/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import WatchConnectivity
import CoreLock
import LockKit

final class WatchController: NSObject {
    
    static let shared = WatchController()
    
    private override init() { }
    
    var log: ((String) -> ())?
    
    var context: WatchApplicationContext? {
        didSet { if context != oldValue { updateApplicationContext() } }
    }
    
    var keys: ((UUID) -> (KeyData?))?
    
    /// The object that initiates communication between a WatchKit extension and its companion iOS app.
    private let session: WCSession = .default
    
    /// Returns a Boolean value indicating whether the current iOS device is able to use a session object.
    static var isSupported: Bool {
        return WCSession.isSupported()
    }
    
    /// The current activation state of the session.
    @available(iOS 9.3, *)
    var activationState: WCSessionActivationState {
        return session.activationState
    }
    
    /// A Boolean value indicating whether the counterpart app is available for live messaging.
    @available(iOS 9.3, *)
    var isReachable: Bool? {
        guard session.activationState == .activated
            else { return nil }
        return session.isReachable
    }
    
    /// A Boolean value indicating whether the Watch app is installed on the currently paired and active Apple Watch.
    @available(iOS 9.3, *)
    var isWatchAppInstalled: Bool? {
        guard session.activationState == .activated
            else { return nil }
        return session.isWatchAppInstalled
    }
    
    /// A Boolean indicating whether the current iPhone is paired to an Apple Watch.
    @available(iOS 9.3, *)
    var isPaired: Bool? {
        guard session.activationState == .activated
            else { return nil }
        return session.isPaired
    }
    
    // MARK: - Methods
    
    /// Activates the session asynchronously.
    func activate() {
        
        if #available(iOS 9.3, *) {
            guard session.activationState != .activated
                else { return }
        }
        
        log?("Request session activation")
        
        session.delegate = self
        session.activate()
    }
    
    private func updateApplicationContext() {
        
        // session must be activated first
        if #available(iOS 9.3, *) {
            guard session.activationState == .activated
                else { return }
        }
        
        guard session.isPaired else { return }
        
        let message = context?.toMessage() ?? [:]
        do { try session.updateApplicationContext(message) }
        catch {
            log?("⚠️ Unable to update application context: \(error)")
            return
        }
        
        log?("Updated application context")
    }
    
    private func response(for message: [String: Any]) -> WatchMessage.Response {
        
        guard let message = WatchMessage(message: message)
            else { return .error("Invalid message") }
        
        return response(for: message)
    }
    
    private func response(for message: WatchMessage) -> WatchMessage.Response {
        
        switch message {
        case let .request(request):
            return response(for: request)
        case .response:
            return .error("Invalid request")
        }
    }
    
    private func response(for request: WatchMessage.Request) -> WatchMessage.Response {
        
        switch request {
        case .applicationData:
            guard let applicationData = self.context?.applicationData
                else { return .error("No application data") }
            return .applicationData(applicationData)
        case let .key(identifier):
            guard let keyData = self.keys?(identifier)
                else { return .error("Invalid key") }
            return .key(keyData)
        }
    }
    
    private func sessionStateChanged() {
        
        guard #available(iOS 9.3, *) else {
            updateApplicationContext()
            return
        }
        
        guard let isPaired = WatchController.shared.isPaired, isPaired
            else { return }
        
        log?("Watch is paired")
        
        guard let isWatchAppInstalled = WatchController.shared.isWatchAppInstalled
            else { return }
        
        guard isWatchAppInstalled else {
            log?("Watch app is not installed")
            return
        }
        
        // update context, regardless of reachability
        updateApplicationContext()
        
        if let isReachable = WatchController.shared.isReachable, isReachable {
            log?("Watch app is reachable")
        } else {
            log?("Watch app is not reachable")
        }
    }
}

// MARK: - WCSessionDelegate

@objc
extension WatchController: WCSessionDelegate {
    
    @objc
    func sessionDidBecomeInactive(_ session: WCSession) {
        
        log?("Session did become inactive")
        
        sessionStateChanged()
    }
    
    @objc
    func sessionDidDeactivate(_ session: WCSession) {
        
        log?("Session did deactivate")
        
        sessionStateChanged()
    }
    
    @available(iOS 9.3, *)
    @objc
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Swift.Error?) {
        
        if let error = error {
            log?("Activation did not complete: " + error.localizedDescription)
            #if DEBUG
            dump(error)
            #endif
        } else {
            log?(activationState.debugDescription)
        }
        
        sessionStateChanged()
    }
    
    @objc(sessionReachabilityDidChange:)
    func sessionReachabilityDidChange(_ session: WCSession) {
        
        log?("Session reachable: \(session.isReachable)")
        
        updateApplicationContext()
    }
    
    @objc(sessionWatchStateDidChange:)
    func sessionWatchStateDidChange(_ session: WCSession) {
        
        log?("Watch state did change")
        
        sessionStateChanged()
    }
    
    /** Called on the delegate of the receiver. Will be called on startup if the incoming message caused the receiver to launch. */
    @objc(session:didReceiveMessage:)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        log?("Recieved message")
        if #available(iOS 9.3, *) {
            guard session.activationState == .activated else {
                log?("Session not active, will not respond")
                return
            }
        }
        let response = self.response(for: message)
        let responseMessage = WatchMessage.response(response).toMessage()
        guard session.isReachable else {
            log?("Session not reachable, will not respond")
            return
        }
        session.sendMessage(responseMessage, replyHandler: { [weak self] (reply) in
            self?.log?("Reply: \(reply)")
        }, errorHandler: { [weak self] (error) in
            self?.log?("Unable to respond: \(error)")
        })
    }
    
    /** Called on the delegate of the receiver when the sender sends a message that expects a reply. Will be called on startup if the incoming message caused the receiver to launch. */
    @objc
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        log?("Recieved message")
        #if DEBUG
        dump(message)
        #endif
        let response = self.response(for: message)
        let responseMessage = WatchMessage.response(response).toMessage()
        replyHandler(responseMessage)
    }
    
    /** Called on the delegate of the receiver. Will be called on startup if the incoming message data caused the receiver to launch. */
    @objc
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        
        log?("Recieved message data: \(messageData)")
    }
    
    /** Called on the delegate of the receiver when the sender sends message data that expects a reply. Will be called on startup if the incoming message data caused the receiver to launch. */
    @objc
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        
        log?("Recieved message data: \(messageData)")
    }
}

@available(iOS 9.3, *)
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
