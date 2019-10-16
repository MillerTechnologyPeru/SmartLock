//
//  File.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation
import CoreLock
import Kitura
import KituraContracts

internal extension LockWebServer {
    
    func addLockInformationRoute() {
        
        router.get("/info", handler: getLockInformation)
    }
    
    func getLockInformation(completion: (LockNetService.LockInformation?, RequestError?) -> ()) {
        
        let status: LockStatus = authorization.isEmpty ? .setup : .unlock
        
        let identifier = configurationStore.configuration.identifier
        
        let information = LockNetService.LockInformation(identifier: identifier,
                                                         buildVersion: .current,
                                                         version: .current,
                                                         status: status,
                                                         unlockActions: [UnlockAction.default])
        
        completion(information, nil)
    }
}
