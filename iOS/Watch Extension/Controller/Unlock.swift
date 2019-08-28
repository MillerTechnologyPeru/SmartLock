//
//  Unlock.swift
//  Watch Extension
//
//  Created by Alsey Coleman Miller on 8/28/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import WatchKit
import CoreLock

public extension ActivityInterface {
    
    func unlock(lock identifier: UUID, peripheral: LockPeripheral<NativeCentral>) {
        
        let needsSync: Bool
        if let lockCache = Store.shared[lock: identifier] {
            needsSync = Store.shared[key: lockCache.key.identifier] == nil
        } else {
            needsSync = true
        }
        if needsSync {
            Store.shared.syncApp()
        }
        performActivity({
            try Store.shared.unlock(peripheral)
        }, completion: { (controller, _) in
            WKInterfaceDevice.current().play(.success)
        })
    }
}
