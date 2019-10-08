//
//  URL.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 7/12/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public enum LockURL: Equatable, Hashable {
    
    case setup(lock: UUID, secret: KeyData)
    case unlock(lock: UUID)
    case newKey(NewKey.Invitation)
}

public extension LockURL {
    
    static var scheme: String = "lock"
}

internal extension LockURL {
    
    var type: URLType {
        switch self {
        case .setup: return .setup
        case .unlock: return .unlock
        case .newKey: return .newKey
        }
    }
    
    enum URLType: String {
        
        case setup
        case unlock
        case newKey = "newkey"
        
        var componentsCount: Int {
            switch self {
            case .setup:
                return 3
            case .unlock:
                return 2
            case .newKey:
                return 2
            }
        }
    }
}

extension LockURL: RawRepresentable {
    
    public init?(rawValue url: URL) {
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        guard url.scheme == Swift.type(of: self).scheme,
            let type = pathComponents.first.flatMap({ URLType(rawValue: $0.lowercased()) }),
            pathComponents.count == type.componentsCount
            else { return nil }
        
        switch type {
        case .setup:
            guard let lockIdentifier = UUID(uuidString: pathComponents[1]),
                let secretBase64 = Data(base64Encoded: pathComponents[2]),
                let secret = KeyData(data: secretBase64)
                else { return nil }
            self = .setup(lock: lockIdentifier, secret: secret)
        case .unlock:
            guard let lockIdentifier = UUID(uuidString: pathComponents[1])
                else { return nil }
            self = .unlock(lock: lockIdentifier)
        case .newKey:
            guard let data = Data(base64Encoded: pathComponents[1]),
                let invitation = try? JSONDecoder().decode(NewKey.Invitation.self, from: data)
                else { return nil }
            self = .newKey(invitation)
        }
    }
    
    public var rawValue: URL {
        
        let type = self.type
        var path = [String]()
        path.reserveCapacity(type.componentsCount)
        path.append(type.rawValue)
        switch self {
        case let .setup(lock: lockIdentifier, secret: secretData):
            path.append(lockIdentifier.uuidString)
            path.append(secretData.data.base64EncodedString())
        case let .unlock(lock: lockIdentifier):
            path.append(lockIdentifier.uuidString)
        case let .newKey(newKey):
            let data = try! JSONEncoder().encode(newKey)
            let base64 = data.base64EncodedString()
            path.append(base64)
        }
        var components = URLComponents()
        components.scheme = Swift.type(of: self).scheme
        components.path = path.reduce("", { $0 + "/" + $1 })
        guard let url = components.url
            else { fatalError("Could not compose URL") }
        return url
    }
}
