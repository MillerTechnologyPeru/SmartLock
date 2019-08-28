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
    
    public var timeout: TimeInterval = 5.0
    
    public var log: ((String) -> ())?
    
    internal let session: WCSession = .default

    @available(iOS 9.3, *)
    public var activationState: WCSessionActivationState {
        return session.activationState
    }
    
    public var isReachable: Bool {
        return session.isReachable
    }
    
    private var operationState: (semaphore: DispatchSemaphore, error: Swift.Error?)?
    
    private var lastMessage: [String: Any]?
    
    // MARK: - Mehods
    
    public func activate() throws {
        
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
}

// MARK: - WCSessionDelegate

@objc
extension SessionController: WCSessionDelegate {
    
    
    @objc @available(iOS 9.3, *)
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Swift.Error?) {
        
        log?("Activation did complete with state: \(activationState) \(error?.localizedDescription ?? "")")
        
        guard activationState == .activated && session.isReachable else {
            let error: Swift.Error = error ?? Error.notReachable
            stopWaiting(error)
            return
        }
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
