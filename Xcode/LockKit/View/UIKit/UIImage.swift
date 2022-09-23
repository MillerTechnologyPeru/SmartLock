//
//  UIImage.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/23/22.
//

#if canImport(UIKit)
import Foundation
import UIKit

public extension UIImage {
    
    @available(iOS 8.0, watchOS 6.0, *)
    convenience init?(lockKit name: String) {
        self.init(named: name, in: .lockKit, compatibleWith: nil)
    }
}
#endif
