//
//  Image.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

public extension UIImage {
    
    static func lockKit(_ name: String) -> UIImage? {
        return self.init(named: name, in: .lockKit, compatibleWith: nil)
    }
}
