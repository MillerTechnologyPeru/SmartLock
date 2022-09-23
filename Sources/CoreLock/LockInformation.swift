//
//  LockInformation.swift
//  
//
//  Created by Alsey Coleman Miller on 9/16/22.
//

import Foundation

public struct LockInformation: Equatable, Hashable, Codable, Identifiable {
    
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
