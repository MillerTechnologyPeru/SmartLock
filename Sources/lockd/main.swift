//
//  main.swift
//  lockd
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

#if os(Linux)
import Glibc
import BluetoothLinux
#elseif os(macOS)
import Darwin
import BluetoothDarwin
import DarwinGATT
#endif

import Foundation
import CoreFoundation
import Dispatch

import Bluetooth
import GATT
import CoreLock
import CoreLockGATTServer

#if os(Linux)
typealias LinuxPeripheral = GATTPeripheral<BluetoothLinux.HostController, BluetoothLinux.L2CAPSocket>
var controller: LockController<LinuxPeripheral>?
#elseif os(macOS)
var controller: LockController<DarwinPeripheral>?
#endif

var gpio: LockGPIOController?

func run() throws {
    
    guard let hostController = HostController.default
        else { throw LockGATTServerError.bluetoothUnavailible }
    
    let address = try hostController.readDeviceAddress()
    
    print("Bluetooth Controller: \(address)")
    
    func peripheralLog(_ message: String) {
        print("Peripheral:", message)
    }
    
    #if os(Linux)
    let serverSocket = try L2CAPSocket.lowEnergyServer(
        controllerAddress: address,
        isRandom: false,
        securityLevel: .low
    )
    let options = GATTPeripheralOptions(
        maximumTransmissionUnit: .max,
        maximumPreparedWrites: 1000
    )
    let peripheral = LinuxPeripheral(controller: hostController, options: options)
    peripheral.newConnection = {
        let socket = try serverSocket.waitForConnection()
        let central = Central(identifier: socket.address)
        peripheralLog("[\(central)]: New \(socket.addressType) connection")
        return (socket, central)
    }
    #elseif os(macOS)
    let peripheral = DarwinPeripheral()
    #endif
    
    print("Initialized \(String(reflecting: type(of: peripheral))) with options:")
    dump(peripheral.options)
    
    peripheral.log = peripheralLog
    
    #if os(macOS)
    // wait until XPC connection to blued is established and hardware is on
    while peripheral.state != .poweredOn { sleep(1) }
    #endif
    
    let configurationStore = try LockConfigurationFile(
        url: URL(fileURLWithPath: "/opt/colemancda/lockd/config.json")
    )
    
    let lockIdentifier = configurationStore.configuration.identifier
    
    print("🔒 Lock \(lockIdentifier)")
    
    // Intialize Smart Connect BLE Controller
    controller = try LockController(peripheral: peripheral)
    
    // load files
    controller?.lockServiceController.configurationStore = configurationStore
    controller?.lockServiceController.authorization = try AuthorizationStoreFile(
        url: URL(fileURLWithPath: "/opt/colemancda/lockd/data.json")
    )
    controller?.lockServiceController.setupSecret = try LockSetupSecretFile(
        createdAt: URL(fileURLWithPath: "/opt/colemancda/lockd/sharedSecret")
    ).sharedSecret
    controller?.lockServiceController.events = LockEventsFile(
        url: URL(fileURLWithPath: "/opt/colemancda/lockd/events.json")
     )
    
    // setup controller
    if let hardware = try? JSONDecoder().decode(LockHardware.self, from: URL(fileURLWithPath: "/opt/colemancda/lockd/hardware.json")) {
        
        print("Running on hardware:")
        dump(hardware)
        
        controller?.hardware = hardware
        
        // load GPIO
        if let gpioController = hardware.gpioController() {
            print("Loaded GPIO Controller: \(type(of: gpioController))")
            controller?.lockServiceController.unlockDelegate = gpioController
            gpio = gpioController
            gpioController.didPressResetButton = {
                print("Reset Button pressed at \(Date())")
                controller?.lockServiceController.reset()
            }
        }
    }
    
    // publish GATT server, enable advertising
    try peripheral.start()
    
    // configure custom advertising
    try hostController.setLockAdvertisingData(lock: lockIdentifier, rssi: 30) // FIXME: RSSI
    try hostController.setLockScanResponse()
    try hostController.writeLocalName("Lock")
    
    // change advertisment for notifications
    controller?.lockServiceController.lockChanged = {
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 2) {
            do {
                try hostController.setNotificationAdvertisement(rssi: 30) // FIXME: RSSI
                sleep(5)
                try hostController.setLockAdvertisingData(lock: lockIdentifier, rssi: 30)
            }
            catch {
                print("Unable to change advertising")
                dump(error)
            }
        }
    }
    
    // run main loop
    RunLoop.main.run()
}

func Error(_ text: String) -> Never {
    print("Exiting with error:", text)
    exit(EXIT_FAILURE)
}

do { try run() }
catch {
    dump(error)
    Error("\(error.localizedDescription)")
}
