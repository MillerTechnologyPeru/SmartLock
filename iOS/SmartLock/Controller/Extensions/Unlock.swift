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
        
        performActivity({
            try Store.shared.unlock(lock, action: action)
        })
    }
}
