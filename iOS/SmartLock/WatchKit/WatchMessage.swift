//
//  WatchMessage.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/28/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock

public enum WatchMessage: Equatable {
    
    case request(Request)
    case response(Response)
}

internal extension WatchMessage {
    
    enum Key: String {
        case request
        case response
        case error
        case applicationData
        case key
    }
}

public extension WatchMessage {
    
    enum Request: Equatable {
        case applicationData
        case key(UUID)
    }
}

public extension WatchMessage {
    
    enum Response: Equatable {
        case error(String)
        case applicationData(ApplicationData)
        case key(KeyData)
    }
}

public extension WatchMessage {
    
    init?(message: [String: Any]) {
        
        if let request = message[Key.request.rawValue] {
            if let requestString = request as? String {
                switch requestString {
                case Key.applicationData.rawValue:
                    self = .request(.applicationData)
                default:
                    return nil
                }
            } else if let requestObject = request as? [String: Any] {
                if let keyString = requestObject[Key.key.rawValue] as? String {
                    guard let identifier = UUID(uuidString: keyString)
                        else { return nil }
                    self = .request(.key(identifier))
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } else if let response = message[Key.response.rawValue] as? [String: Any] {
            if let data = response[Key.applicationData.rawValue] as? Data {
                guard let value = try? ApplicationData.decodeJSON(from: data)
                    else { return nil }
                self = .response(.applicationData(value))
            } else if let data = response[Key.key.rawValue] as? Data {
                guard let keyData = KeyData(data: data)
                    else { return nil }
                self = .response(.key(keyData))
            } else if let error = response[Key.error.rawValue] as? String {
                self = .response(.error(error))
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func toMessage() -> [String: Any] {
        switch self {
        case .request(.applicationData):
            return [
                Key.request.rawValue: Key.applicationData.rawValue
            ]
        case let .request(.key(identifier)):
            return [
                Key.request.rawValue: [
                    Key.key.rawValue: identifier.uuidString
                ]
            ]
        case let .response(.applicationData(applicationData)):
            return [
                Key.response.rawValue: [
                    Key.applicationData.rawValue: applicationData.encodeJSON()
                ]
            ]
        case let .response(.key(keyData)):
            return [
                Key.response.rawValue: [
                    Key.key.rawValue: keyData.data
                ]
            ]
        case let .response(.error(message)):
            return [
                Key.response.rawValue: [
                    Key.error.rawValue: message
                ]
            ]
        }
    }
}
