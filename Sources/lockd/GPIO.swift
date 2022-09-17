//
//  GPIO.swift
//  lockd
//
//  Created by Alsey Coleman Miller on 6/25/19.
//

import Foundation
import Dispatch
import CoreLock
import CoreLockGATTServer
import SwiftyGPIO

public protocol LockGPIOController: AnyObject, UnlockDelegate {
    
    var relay: GPIOState { get set }
    
    var led: GPIOState { get set }
    
    var didPressResetButton: () -> () { get set }
}

/// GPIO State
public enum GPIOState: Int {
    
    case low = 0
    case high = 1
}

public extension LockGPIOController {
    
    func unlock(_ action: UnlockAction) throws {
        
        relay = .low
        sleep(1)
        relay = .high
    }
}

internal extension LockHardware {
    
    func gpioController() -> LockGPIOController? {
        
        switch model {
        case .orangePiOne:
            return OrangePiOneGPIO()
        case .orangePiZero:
            return OrangePiZeroGPIO()
        case .raspberryPi3:
            return RaspberryPi3GPIO()
        default:
            return nil
        }
    }
}

public class OrangePiOneGPIO: LockGPIOController {
    
    private var tappedSeconds: UInt = 0
    
    public var heldInterval: UInt = 5
    
    public init() {
        DispatchQueue.global(qos: .background).async {
            while true {
                usleep(2000)
                if self.resetSwitchGPIO.value == 1 {
                    self.tappedSeconds += 1
                    if self.tappedSeconds == 1000 * self.heldInterval {
                        self.didPressResetButton()
                    }
                } else {
                    self.tappedSeconds = 0
                }
            }
        }
    }
    
    internal lazy var relayGPIO: GPIO = {
        let gpio = GPIO(sunXi: SunXiGPIO(letter: .A, pin: 6))
        gpio.direction = .OUT
        return gpio
    }()
    
    internal lazy var ledGPIO: GPIO = {
        let gpio = GPIO(sunXi: SunXiGPIO(letter: .A, pin: 1))
        gpio.direction = .OUT
        return gpio
    }()
    
    internal lazy var resetSwitchGPIO: GPIO = {
        let gpio = GPIO(sunXi: SunXiGPIO(letter: .D, pin: 14))
        gpio.direction = .IN
        return gpio
    }()
    
    public var relay: GPIOState = .low {
        didSet { relayGPIO.value = relay.rawValue }
    }
    
    public var led: GPIOState = .low {
        didSet { ledGPIO.value = led.rawValue }
    }
    
    public var didPressResetButton: () -> () = { }
}

public final class OrangePiZeroGPIO: OrangePiOneGPIO { }

public final class RaspberryPi3GPIO: LockGPIOController {
    
    public init() {
        self.resetSwitchGPIO.bounceTime = 10
        self.resetSwitchGPIO.onRaising { [weak self] in
            if $0.value == 1 {
                self?.didPressResetButton()
            }
        }
    }
    
    internal lazy var relayGPIO: RaspberryGPIO = {
        let gpio = RaspberryGPIO(name:"GPIO23", id:23, baseAddr:0x3F000000)
        gpio.direction = .OUT
        return gpio
    }()
    
    internal lazy var ledGPIO: RaspberryGPIO = {
        let gpio = RaspberryGPIO(name:"GPIO16", id:16, baseAddr:0x3F000000)
        gpio.direction = .OUT
        return gpio
    }()
    
    internal lazy var resetSwitchGPIO: RaspberryGPIO = {
        let gpio = RaspberryGPIO(name:"GPIO12", id:12, baseAddr:0x3F000000)
        gpio.direction = .IN
        return gpio
    }()
    
    public var relay: GPIOState = .low {
        didSet { relayGPIO.value = relay.rawValue }
    }
    
    public var led: GPIOState = .low {
        didSet { ledGPIO.value = led.rawValue }
    }
    
    public var didPressResetButton: () -> () = { }
}
