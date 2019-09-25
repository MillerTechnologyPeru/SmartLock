//
//  Bundle.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public extension Bundle {
    
    /// LockKit Bundle
    static var lockKit: Bundle {
        struct Cache {
            static let bundle = Bundle(for: Store.self)
        }
        return Cache.bundle
    }
}

public extension Bundle {
    
    enum Lock: String {
        
        case app = "com.colemancda.Lock"
        case macApp = "maccatalyst.com.colemancda.Lock"
        case watch = "com.colemancda.Lock.watchkitapp.watchkitextension"
        case coreLock = "com.colemancda.CoreLock"
        case lockKit = "com.colemancda.LockKit"
        case intent = "com.colemancda.Lock.Intent"
        case intentUI = "com.colemancda.Lock.IntentUI"
        case message = "com.colemancda.Lock.Message"
        case today = "com.colemancda.Lock.Today"
        case quickLook = "com.colemancda.Lock.QuickLook"
        case thumbnail = "com.colemancda.Lock.Thumbnail"
    }
}

public extension Bundle.Lock {
    
    var symbol: String {
        switch self {
        case .app:
            return "📱"
        case .macApp:
            return "💻"
        case .watch:
            return "⌚️"
        case .coreLock,
             .lockKit:
            return "🔒"
        case .intent,
             .intentUI:
            return "🎙"
        case .message:
            return "✉️"
        case .today:
            return "☀️"
        case .quickLook:
            return "👁‍🗨"
        case .thumbnail:
            return "🖼"
        }
    }
    
    var localizedText: String {
        
        switch self {
        case .app:
            return "Application"
        case .macApp:
            return "Application"
        case .watch:
            return "Application"
        case .coreLock:
            return "CoreLock"
        case .lockKit:
            return "LockKit"
        case .intent:
            return "Siri Intent"
        case .intentUI:
            return "Siri Intent UI"
        case .message:
            return "Message Extension"
        case .today:
            return "Today Extension"
        case .quickLook:
            return "QuickLook Extension"
        case .thumbnail:
            return "Thumbnail Extension"
        }
    }
}
