//
//  Log.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation

public func log(_ text: String) {
    
    // only print for debug builds
    #if DEBUG
    print(text)
    #endif
}
