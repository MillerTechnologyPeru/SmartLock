//
//  AnimatedButtonController.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 5/1/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import WatchKit

public final class AnimatedButtonController {
    
    /// The names of the sequence of images to animate.
    public let images: [String]
    
    /// The interval between images.
    public let interval: TimeInterval
    
    public weak var target: WKInterfaceButton?
    
    private var currentImageIndex = 0
    
    private var timer: Timer?
    
    deinit { stopAnimating() }
    
    public init(images: [String], interval: TimeInterval, target: WKInterfaceButton?) {
        
        assert(images.count >= 2, "Must provide at least two images")
        
        self.images = images
        self.interval = interval
        self.target = target
    }
    
    // MARK: - Methods
    
    public func startAnimating() {
        
        guard timer == nil else { return }
        
        currentImageIndex = 0
        
        updateImage()
        
        self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(updateImage), userInfo: nil, repeats: true)
    }
    
    public func stopAnimating() {
        
        timer?.invalidate()
        
        timer = nil
    }
    
    // MARK: - Private Methods
    
    @objc private func updateImage() {
        
        let imageName = images[currentImageIndex]
        
        target?.setBackgroundImageNamed(imageName)
        
        currentImageIndex += 1
        
        // reset index to 0
        if currentImageIndex == images.count {
            
            currentImageIndex = 0
        }
    }
}
