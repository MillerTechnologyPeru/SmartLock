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

func run() throws {
    
    guard let hostController = HostController.default
        else { throw SmartLockGATTServerError.bluetoothUnavailible }
    
    print("Bluetooth Controller: \(hostController.address)")
    
    func peripheralLog(_ message: String) {
        print("Peripheral:", message)
    }
    
    #if os(Linux)
    let serverSocket = try L2CAPSocket.lowEnergyServer(controllerAddress: hostController.address,
                                                       isRandom: false,
                                                       securityLevel: .low)
    let mtu = ATTMaximumTransmissionUnit(rawValue: 200)!
    let options = GATTPeripheralOptions(maximumTransmissionUnit: mtu,
                                        maximumPreparedWrites: 100)
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
    
    print("Initialized \(type(of: peripheral)) with options: \(peripheral.options)")
    
    peripheral.log = peripheralLog
    
    #if os(macOS)
    // wait until XPC connection to blued is established and hardware is on
    while peripheral.state != .poweredOn { sleep(1) }
    #endif
    
    // Intialize Smart Connect BLE Controller
    controller = try LockController(peripheral: peripheral)
    
    // setup controller
    controller?.lockServiceController.setupSecret = try LockSetupSecretBase64File(createdAt: URL(fileURLWithPath: "/opt/colemancda/lockd/sharedSecret"))
    
    controller?.lockServiceController.authorization = JSONArchiveAuthorizationStore(url: URL(fileURLWithPath: "/opt/colemancda/lockd/data.json"))
    
    // publish GATT server, enable advertising
    try peripheral.start()
    
    // configure custom advertising
    try hostController.setSmartLockAdvertisingData()
    try hostController.setSmartLockScanResponse()
    
    // run main loop
    while true {
        #if os(Linux)
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, true)
        #elseif os(macOS)
        CFRunLoopRunInMode(.defaultMode, 0.01, true)
        #endif
    }
}

func Error(_ text: String) -> Never {
    print("Exiting with error:", text)
    exit(EXIT_FAILURE)
}

do { try run() }
    
catch { Error("\(error)") }
