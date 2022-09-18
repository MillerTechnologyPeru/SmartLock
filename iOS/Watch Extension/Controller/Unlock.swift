//
//  Unlock.swift
//  Watch Extension
//
//  Created by Alsey Coleman Miller on 8/28/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import WatchKit
import Intents
import CoreLock

public extension ActivityInterface where Self: WKInterfaceController {
    
    func unlock(lock id: UUID, peripheral: NativeCentral.Peripheral) {
        
        let needsSync: Bool
        if let lockCache = Store.shared[lock: id] {
            needsSync = Store.shared[key: lockCache.key.id] == nil
        } else {
            needsSync = true
        }
        if needsSync {
            Store.shared.syncApp()
        }
        performActivity({
            try await Store.shared.unlock(peripheral)
        }, completion: { (controller, hasKey) in
            let haptic: WKHapticType = hasKey ? .success : .failure
            WKInterfaceDevice.current().play(haptic)
        })
    }
}

