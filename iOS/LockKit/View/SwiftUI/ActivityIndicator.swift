//
//  ActivityIndicator.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import SwiftUI

/// A view that shows that a task is in progress.
@available(iOSApplicationExtension 13.0, *)
public struct ActivityIndicator {
    
    private var isAnimated: Bool
    
    public init(isAnimated: Bool = true) {
        self.isAnimated = isAnimated
    }
    
    public func animated(_ isAnimated: Bool) -> ActivityIndicator {
        var result = self
        result.isAnimated = isAnimated
        return result
    }
}

#if os(iOS) || os(tvOS)

import UIKit

@available(iOSApplicationExtension 13.0, *)
extension ActivityIndicator: UIViewRepresentable {
    
    public typealias Context = UIViewRepresentableContext<Self>
    public typealias UIViewType = UIActivityIndicatorView
    
    public func makeUIView(context: Context) -> UIViewType {
        return UIActivityIndicatorView(style: .medium)
    }
    
    public func updateUIView(_ view: UIViewType, context: Context) {
        if isAnimated, view.isAnimating == false {
            view.startAnimating()
        } else if isAnimated == false, view.isAnimating {
            view.stopAnimating()
        }
    }
}

#endif
