//
//  FileManager.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public extension FileManager {
    
    /// Returns the container directory associated with the specified security application group identifier.
    func containerURL(for appGroup: AppGroup) -> URL? {
        return containerURL(forSecurityApplicationGroupIdentifier: appGroup.rawValue)
    }
}
