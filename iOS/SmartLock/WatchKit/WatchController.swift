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
    
    var applicationData: (() -> (ApplicationData))?
    
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
            guard let applicationData = self.applicationData?()
                else { return .error("No application data") }
            return .applicationData(applicationData)
        case let .key(identifier):
            guard let keyData = self.keys?(identifier)
                else { return .error("Invalid key") }
            return .key(keyData)
        }
    }
}

// MARK: - WCSessionDelegate

@objc
extension WatchController: WCSessionDelegate {
    
    @objc
    func sessionDidBecomeInactive(_ session: WCSession) {
        
        log?("Session did become inactive")
    }
    
    @objc
    func sessionDidDeactivate(_ session: WCSession) {
        
        log?("Session did deactivate")
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
        
        if let isPaired = WatchController.shared.isPaired, isPaired {
            log?("Watch is paired")
            if let isWatchAppInstalled = WatchController.shared.isWatchAppInstalled {
                if isWatchAppInstalled {
                    log?("Watch app is installed")
                } else {
                    log?("Watch app is not installed")
                }
            }
        }
    }
    
    @objc(sessionReachabilityDidChange:)
    func sessionReachabilityDidChange(_ session: WCSession) {
        
        log?("Session reachable: \(session.isReachable)")
    }
    
    @objc
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        log?("Recieved message: \(message)")
        if #available(iOS 9.3, *) {
            guard session.activationState == .activated else {
                log?("Session not active, will not respond")
                return
            }
        }
        let response = self.response(for: message)
        log?("Respond with \(response)")
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
