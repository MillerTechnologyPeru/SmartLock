//
//  GPIO.swift
//  lockd
//
//  Created by Alsey Coleman Miller on 6/25/19.
//

import Foundation
import CoreLock
import CoreLockGATTServer
import SwiftyGPIO

public protocol LockGPIOController: class, UnlockDelegate {
    
    var isRelayOn: Bool { get set }
}

public extension LockGPIOController {
    
    func unlock(_ action: UnlockAction) throws {
        
        isRelayOn = true
        sleep(1)
        isRelayOn = false
    }
}

public extension LockHardware {
    
    func gpioController() -> LockGPIOController? {
        
        switch model {
        case LockModel.orangePiOne:
            return OrangePiOneGPIO()
        default:
            return nil
        }
    }
}

public final class OrangePiOneGPIO: LockGPIOController {
    
    internal lazy var relayGPIO: GPIO = {
        let gpio = GPIO(sunXi: SunXiGPIO(letter: .A, pin: 6))
        gpio.direction = .OUT
        gpio.value = 0
        return gpio
    }()
    
    public var isRelayOn: Bool {
        get { return relayGPIO.value != 0 }
        set { relayGPIO.value = newValue ? 1 : 0 }
    }
}
