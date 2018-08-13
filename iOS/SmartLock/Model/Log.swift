//
//  Log.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation

internal func log(_ text: String) {
    
    #if os(iOS)
    print(text)
    #elseif os(Android)
    NSLog(text)
    #endif
}
