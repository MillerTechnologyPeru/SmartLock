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
import Intents

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
        performActivity(queue: .bluetooth, {
            try Store.shared.unlock(peripheral)
        }, completion: { (controller, hasKey) in
            let haptic: WKHapticType = hasKey ? .success : .failure
            WKInterfaceDevice.current().play(haptic)
        })
    }
}

public extension WKInterfaceController {
    
    /// Donate Siri Shortcut to unlock the specified lock.
    func donateUnlockIntent(for lock: UUID) {
        
        guard let lockCache = Store.shared[lock: lock]
            else { return }
        
        if #available(watchOSApplicationExtension 5.0, *) {
            let intent = UnlockIntent(identifier: lock, cache: lockCache)
            let interaction = INInteraction(intent: intent, response: nil)
            interaction.donate { error in
                if let error = error {
                    log("⚠️ Donating intent failed with error \(error.localizedDescription)")
                    #if DEBUG
                    dump(error)
                    #endif
                }
            }
        }
    }
}
