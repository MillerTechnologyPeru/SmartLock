//
//  LockNetService.swift
//  
//
//  Created by Alsey Coleman Miller on 10/16/19.
//

import Foundation

public final class LockNetService {
    
    
}

public extension LockNetService {
    
    struct LockInformation: Equatable, Codable {
        
        /// Lock identifier
        public let identifier: UUID
        
        /// Firmware build number
        public let buildVersion: LockBuildVersion
        
        /// Firmware version
        public let version: LockVersion
        
        /// Device state
        public var status: LockStatus
        
        /// Supported lock actions
        public let unlockActions: Set<UnlockAction>
        
        public init(identifier: UUID,
                    buildVersion: LockBuildVersion = .current,
                    version: LockVersion = .current,
                    status: LockStatus,
                    unlockActions: Set<UnlockAction> = [.default]) {
            
            self.identifier = identifier
            self.buildVersion = buildVersion
            self.version = version
            self.status = status
            self.unlockActions = unlockActions
        }
    }
}
