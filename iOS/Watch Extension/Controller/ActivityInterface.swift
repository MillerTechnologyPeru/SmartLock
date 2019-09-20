//
//  ActivityInterface.swift
//  Watch Extension
//
//  Created by Alsey Coleman Miller on 8/28/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import WatchKit

public protocol ActivityInterface: class {
    
    var activityImageView: WKInterfaceImage? { get }
    
    var contentView: WKInterfaceObject { get }
}

public extension ActivityInterface {
    
    func setupActivityImageView() {
        
        // setup activity indicator
        activityImageView?.setImageNamed("Activity")
        activityImageView?.startAnimatingWithImages(in: NSRange(location: 0, length: 30), duration: 1.0, repeatCount: 0)
    }
    
    func showActivity() {
                
        activityImageView?.setHidden(false)
        activityImageView?.startAnimating()
        contentView.setHidden(true)
    }
    
    func hideActivity() {
        
        contentView.setHidden(false)
        activityImageView?.setHidden(true)
        activityImageView?.stopAnimating()
    }
}

public extension ActivityInterface where Self: WKInterfaceController {
    
    func performActivity <T> (showActivity: Bool = true,
                              queue: DispatchQueue? = nil,
                              _ asyncOperation: @escaping () throws -> T,
                              completion: ((Self, T) -> ())? = nil) {
        
        assert(Thread.isMainThread)
        
        let queue = queue ?? .app
        
        if showActivity { self.showActivity() }
        
        queue.async {
            
            do {
                
                let value = try asyncOperation()
                
                mainQueue { [weak self] in
                    
                    guard let controller = self
                        else { return }
                    
                    if showActivity { controller.hideActivity() }
                    
                    // success
                    completion?(controller, value)
                }
            }
                
            catch {
                
                mainQueue { [weak self] in
                    
                    guard let controller = self
                        else { return }
                    
                    if showActivity { controller.hideActivity() }
                    
                    // show error
                    log("⚠️ Error: \(error.localizedDescription)")
                    #if DEBUG
                    print(error)
                    #endif
                    controller.showError(error.localizedDescription)
                }
            }
        }
    }
}
