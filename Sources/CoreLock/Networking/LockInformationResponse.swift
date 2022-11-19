//
//  LockInformationResponse.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 10/16/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public extension LockNetService {
    
    struct LockInformation: Equatable, Hashable, Codable, Identifiable {
        
        /// Lock identifier
        public let id: UUID
        
        /// Firmware build number
        public let buildVersion: LockBuildVersion
        
        /// Firmware version
        public let version: LockVersion
        
        /// Device state
        public var status: LockStatus
        
        /// Supported lock actions
        public let unlockActions: Set<UnlockAction>
        
        public init(id: UUID,
                    buildVersion: LockBuildVersion = .current,
                    version: LockVersion = .current,
                    status: LockStatus,
                    unlockActions: Set<UnlockAction> = [.default]) {
            
            self.id = id
            self.buildVersion = buildVersion
            self.version = version
            self.status = status
            self.unlockActions = unlockActions
        }
    }
}
