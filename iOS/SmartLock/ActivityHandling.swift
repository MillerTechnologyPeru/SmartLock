//
//  ActivityHandling.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/18/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock
import UIKit

protocol LockActivityHandling {
    
    func handle(url: LockURL)
    
    func handle(activity: AppActivity)
}

// MARK: - View Controller

protocol LockActivityHandlingViewController: class, LockActivityHandling { }
