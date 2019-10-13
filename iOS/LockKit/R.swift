//
//  R.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/23/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

#if DEBUG
public struct RLockKit {
    public static func validate() throws {
        try R.validate()
    }
}
#endif
