//
//  Intent.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import Intents

@available(iOS 12, iOSApplicationExtension 12.0, *)
public extension UnlockIntent {
    
    convenience init(lock identifier: UUID, name: String) {
        
        self.init()
        self.lock = INObject(identifier: identifier.uuidString, display: name)
    }
}
