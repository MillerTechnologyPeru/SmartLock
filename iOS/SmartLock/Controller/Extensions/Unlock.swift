//
//  Unlock.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/19/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreLock

extension ActivityIndicatorViewController where Self: UIViewController {
    
    func unlock(lock identifier: UUID, action: UnlockAction = .default,  scanDuration: TimeInterval = 2.0) {
        
        self.userActivity = NSUserActivity(.action(.unlock(identifier)))
        self.userActivity?.becomeCurrent()
        
        performActivity({ () -> String? in
            guard let lockPeripheral = try Store.shared.device(for: identifier, scanDuration: scanDuration)
                else { return "Could not find lock" }
            return try Store.shared.unlock(lockPeripheral, action: action) ? nil : "Unable to unlock"
        }, completion: { (viewController, errorMessage) in
            if let errorMessage = errorMessage {
                viewController.showErrorAlert(errorMessage)
            }
        })
    }
    
    func unlock(lock: LockPeripheral<NativeCentral>, action: UnlockAction = .default) {
        
        if let lockInformation = Store.shared.lockInformation.value[lock.scanData.peripheral] {
            userActivity?.resignCurrent()
            lastUnlockActivity = NSUserActivity(.action(.unlock(lockInformation.identifier)))
            lastUnlockActivity?.becomeCurrent()
        }
        
        performActivity({
            try Store.shared.unlock(lock, action: action)
        }, completion: { (viewController, _) in
            //lastUnlockActivity?.invalidate()
            viewController.userActivity?.becomeCurrent()
        })
    }
}

private var lastUnlockActivity: NSUserActivity?
