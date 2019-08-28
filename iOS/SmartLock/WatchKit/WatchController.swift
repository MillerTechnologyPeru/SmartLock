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
    
    private let session: WCSession = .default
    
    @available(iOS 9.3, *)
    var activationState: WCSessionActivationState {
        return session.activationState
    }
    
    var isReachable: Bool {
        return session.isReachable
    }
    
    // MARK: - Methods
    
    func activate() {
        
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
        
        log?("Activation did complete with state: \(activationState) \(error?.localizedDescription ?? "")")
        
        #if DEBUG
        if let error = error {
            dump(error)
        }
        #endif
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
        session.sendMessage(responseMessage, replyHandler: { [weak self] (reply) in
            self?.log?("Reply: \(reply)")
        }, errorHandler: { [weak self] (error) in
            self?.log?("Unable to respond: \(error)")
        })
    }
}
