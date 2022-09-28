//
//  PresentationStyle.swift
//  LockMessage
//
//  Created by Alsey Coleman Miller on 9/27/22.
//

import Foundation
import Messages

internal extension MSMessagesAppPresentationStyle {
    
    var debugDescription: String {
        
        switch self {
        case .compact:
            return "compact"
        case .expanded:
            return "expanded"
        case .transcript:
            return "transcript"
        @unknown default:
            assertionFailure("Unknown state \(rawValue)")
            return "Style \(rawValue)"
        }
    }
}
