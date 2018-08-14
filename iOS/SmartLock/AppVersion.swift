//
//  Version.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/13/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation

/** Version of the app. */
public let AppVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

/** Build of the app. */
public let AppBuild = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
