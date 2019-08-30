//
//  WatchApplicationContext.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/30/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public struct WatchApplicationContext: Codable, Equatable {
    
    public var applicationData: ApplicationData
    
    public init(applicationData: ApplicationData) {
        self.applicationData = applicationData
    }
}

public extension WatchApplicationContext {
    
    init?(message: [String: Any]) {
        
        guard let applicationDataBytes = message[CodingKeys.applicationData.stringValue] as? Data,
            let applicationData = try? ApplicationData.decodeJSON(from: applicationDataBytes)
            else { return nil }
        
        self.applicationData = applicationData
    }
    
    func toMessage() -> [String: Any] {
        var message = [String: Any]()
        message[CodingKeys.applicationData.stringValue] = applicationData.encodeJSON()
        return message
    }
}
