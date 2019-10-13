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
import Dispatch

public protocol LockGPIOController: class, UnlockDelegate {
    
    var relay: GPIOState { get set }
    
    var led: GPIOState { get set }
    
    var didPressResetButton: () -> () { get set }
    
    var tappedSeconds: UInt { get set }
    
    var heldInterval: UInt { get set }
}

/// GPIO State
public enum GPIOState: Int {
    
    case off = 0
    case on = 1
}

public extension LockGPIOController {
    
    func unlock(_ action: UnlockAction) throws {
        
        relay = .on
        sleep(1)
        relay = .off
    }
}

public extension LockHardware {
    
    func gpioController() -> LockGPIOController? {
        
        switch model {
        case .orangePiOne:
            return OrangePiOneGPIO()
        case .raspberryPi3:
            return RaspberryPi3GPIO()
        default:
            return nil
        }
    }
}

public final class OrangePiOneGPIO: LockGPIOController {
    
    public var tappedSeconds: UInt = 0
    
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
        gpio.value = 0
        return gpio
    }()
    
    internal lazy var ledGPIO: GPIO = {
        let gpio = GPIO(sunXi: SunXiGPIO(letter: .A, pin: 1))
        gpio.direction = .OUT
        gpio.value = 0
        return gpio
    }()
    
    internal lazy var resetSwitchGPIO: GPIO = {
        let gpio = GPIO(sunXi: SunXiGPIO(letter: .D, pin: 14))
        gpio.direction = .IN
        gpio.value = 0
        return gpio
    }()
    
    public var relay: GPIOState {
        get { return GPIOState(rawValue: relayGPIO.value) ?? .off }
        set { relayGPIO.value = newValue.rawValue }
    }
        
    public var led: GPIOState {
        get { return GPIOState(rawValue: ledGPIO.value) ?? .off }
        set { ledGPIO.value = newValue.rawValue }
    }
    
    public var didPressResetButton: () -> () = { }
}

public final class RaspberryPi3GPIO: LockGPIOController {
    
    public var tappedSeconds: UInt = 0
    
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
        let gpio = RaspberryGPIO(name:"GPIO23", id:23, baseAddr:0x3F000000)
        gpio.direction = .OUT
        gpio.value = 0
        return gpio
    }()
    
    internal lazy var ledGPIO: GPIO = {
        let gpio = RaspberryGPIO(name:"GPIO16", id:16, baseAddr:0x3F000000)
        gpio.direction = .OUT
        gpio.value = 0
        return gpio
    }()
    
    internal lazy var resetSwitchGPIO: GPIO = {
        let gpio = RaspberryGPIO(name:"GPIO12", id:12, baseAddr:0x3F000000)
        gpio.direction = .IN
        gpio.value = 0
        return gpio
    }()
    
    public var relay: GPIOState {
        get { return GPIOState(rawValue: relayGPIO.value) ?? .off }
        set { relayGPIO.value = newValue.rawValue }
    }
    
    public var led: GPIOState {
        get { return GPIOState(rawValue: ledGPIO.value) ?? .off }
        set { ledGPIO.value = newValue.rawValue }
    }
    
    public var didPressResetButton: () -> () = { }
}
