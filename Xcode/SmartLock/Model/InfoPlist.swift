//
//  InfoPlist.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/13/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation

extension Bundle {
    
    /// Info.plist Key
    enum InfoKey: String {
        case version = "CFBundleVersion"
        case shortVersion = "CFBundleShortVersionString"
    }
    
    fileprivate subscript (key: InfoKey) -> Any? {
        return infoDictionary?[key.rawValue]
    }
}

extension Bundle {
    
    /// Info.plist
    enum InfoPlist {
        
        private static let bundle: Bundle = .main
        
        /** Version of the app. */
        static let version = bundle[.version] as! String
        
        /** Build of the app. */
        static let shortVersion = bundle[.shortVersion] as! String
    }
}
