//
//  Preferences.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public extension UserDefaults {
    
    convenience init?(suiteName appGroup: AppGroup) {
        self.init(suiteName: appGroup.rawValue)
    }
}

public extension UserDefaults {
    
    var isAppInstalled: Bool {
        get { return self[.isAppInstalled] ?? false }
        set { self[.isAppInstalled] = newValue }
    }
    
    var isCloudEnabled: Bool {
        get { return self[.isCloudEnabled] ?? false }
        set { self[.isCloudEnabled] = newValue }
    }
    
    var lastCloudUpdate: Date? {
        get { return self[.lastCloudUpdate] }
        set { self[.lastCloudUpdate] = newValue }
    }
    
    var lastWatchUpdate: Date? {
        get { return self[.lastWatchUpdate] }
        set { self[.lastWatchUpdate] = newValue }
    }
}

private extension UserDefaults {
    
    subscript <T> (key: Key) -> T? {
        
        get { return object(forKey: key.rawValue) as? T }
        set { set(newValue, forKey: key.rawValue) }
    }
}

internal extension UserDefaults {
    
    enum Key: String {
        
        case isAppInstalled
        case isCloudEnabled
        case lastCloudUpdate
        case lastWatchUpdate
    }
}
