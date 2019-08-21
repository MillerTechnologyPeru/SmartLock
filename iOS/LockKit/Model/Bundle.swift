//
//  Bundle.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation

public extension Bundle {
    
    static var lockKit: Bundle {
        return Bundle(for: Store.self)
    }
}
