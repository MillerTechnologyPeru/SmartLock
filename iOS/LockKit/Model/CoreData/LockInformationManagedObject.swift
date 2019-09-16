//
//  LockInformationManagedObject.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreData
import CoreLock

public final class LockInformationManagedObject: NSManagedObject {
    
    internal convenience init(_ value: LockCache.Information, context: NSManagedObjectContext) {
        self.init(context: context)
        update(value)
    }
    
    internal func update(_ value: LockCache.Information) {
        
        self.buildVersion = numericCast(value.buildVersion.rawValue)
        self.versionMajor = numericCast(value.version.major)
        self.versionMinor = numericCast(value.version.minor)
        self.versionPatch = numericCast(value.version.patch)
        self.status = numericCast(value.status.rawValue)
        self.defaultUnlockAction = value.unlockActions.contains(.default)
        self.buttonUnlockAction = value.unlockActions.contains(.button)
    }
}

internal extension LockCache.Information {
    
    init?(managedObject: LockInformationManagedObject) {
        guard let status = LockStatus(rawValue: numericCast(managedObject.status))
            else { return nil }
        self.status = status
        self.buildVersion = LockBuildVersion(rawValue: numericCast(managedObject.buildVersion))
        self.version = LockVersion(
            major: numericCast(managedObject.versionMajor),
            minor: numericCast(managedObject.versionMinor),
            patch: numericCast(managedObject.versionPatch)
        )
        self.unlockActions = []
        if managedObject.defaultUnlockAction {
            self.unlockActions.insert(.default)
        }
        if managedObject.buttonUnlockAction {
            self.unlockActions.insert(.button)
        }
    }
}
