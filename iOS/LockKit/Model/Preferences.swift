//
//  Preferences.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public final class Preferences {
    
    
}

public extension UserDefaults {
    
    convenience init?(suiteName appGroup: AppGroup) {
        self.init(suiteName: appGroup.rawValue)
    }
}
