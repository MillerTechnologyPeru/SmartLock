//
//  GPIO.swift
//  lockd
//
//  Created by Alsey Coleman Miller on 6/25/19.
//

import Foundation
import SwiftyGPIO

public protocol LockGPIOController: class {
    
    func activateLockRelay()
}

public final class OrangePiOneGPIO: LockGPIOController {
    
    internal lazy var relayGPIO: GPIO = {
        let gpio = GPIO(sunXi: SunXiGPIO(letter: .A, pin: 6))
        gpio.direction = .OUT
        gpio.value = 0
        return gpio
    }()
    
    public func activateLockRelay() {
        
        relayGPIO.value = 1
    }
}
