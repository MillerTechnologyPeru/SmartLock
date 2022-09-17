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
import DarwinGATT
#endif

import Foundation
import CoreFoundation
import Dispatch

import Bluetooth
import GATT
import CoreLock
import CoreLockGATTServer
//import CoreLockWebServer

#if os(Linux)
typealias LinuxCentral = GATTCentral<BluetoothLinux.HostController, BluetoothLinux.L2CAPSocket>
typealias LinuxPeripheral = GATTPeripheral<BluetoothLinux.HostController, BluetoothLinux.L2CAPSocket>
typealias NativeCentral = LinuxCentral
typealias NativePeripheral = LinuxPeripheral
#elseif os(macOS)
typealias NativeCentral = DarwinCentral
typealias NativePeripheral = DarwinPeripheral
#else
#error("Unsupported platform")
#endif

/// Lock Daemon
@main
struct LockDaemon {
    
    static var id: UUID { controller.lockServiceController.configurationStore.configuration.id }
    private static var controller: LockGATTController<NativePeripheral>!
    private static var hostController: BluetoothHostControllerInterface?
    private static var gpio: LockGPIOController?
    //static let webServer = LockWebServer()
    
    static func main() {
        
        // start async code
        Task {
            do {
                try await start()
            }
            catch {
                fatalError("\(error)")
            }
        }
        
        // run main loop
        RunLoop.current.run()
    }
    
    private static func start() async throws {
        
        #if os(Linux)
        hostController = await HostController.default
        // keep trying to load Bluetooth device
        while hostController == nil {
            print("No Bluetooth adapters found")
            try await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            hostController = await HostController.default
        }

        let address = try await hostController!.readDeviceAddress()
        print("Bluetooth Controller: \(address)")
        let serverOptions = GATTPeripheralOptions(
            maximumTransmissionUnit: .max,
            maximumPreparedWrites: 1000
        )
        let peripheral = LinuxPeripheral(
            hostController: hostController,
            options: serverOptions,
            socket: BluetoothLinux.L2CAPSocket.self
        )
        #elseif os(macOS)
        let peripheral = DarwinPeripheral()
        #endif
        
        print("Initialized \(String(reflecting: type(of: peripheral))) with options:")
        dump(peripheral.options)
        
        peripheral.log = { print("Peripheral:", $0) }
        
        #if os(macOS)
        // wait until XPC connection to blued is established and hardware is on
        try await peripheral.waitPowerOn()
        #endif
        
        // load files
        let configurationStore = try LockConfigurationFile(
            url: URL(fileURLWithPath: "/opt/colemancda/lockd/config.json")
        )
        let authorization = try AuthorizationStoreFile(
            url: URL(fileURLWithPath: "/opt/colemancda/lockd/data.json")
        )
        let events = LockEventsFile(
            url: URL(fileURLWithPath: "/opt/colemancda/lockd/events.json")
        )
        let setupSecret = try LockSetupSecretFile(
            createdAt: URL(fileURLWithPath: "/opt/colemancda/lockd/sharedSecret")
        )
        
        let lockIdentifier = configurationStore.configuration.id
        
        print("🔒 Lock \(lockIdentifier)")
        
        // configure Smart Connect BLE Controller
        controller = try await LockGATTController(peripheral: peripheral)
        controller?.lockServiceController.configurationStore = configurationStore
        controller?.lockServiceController.authorization = authorization
        controller?.lockServiceController.events = events
        controller?.lockServiceController.setupSecret = setupSecret.sharedSecret
        /*
        // configure web server
        webServer.authorization = authorization
        webServer.configurationStore = configurationStore
        webServer.events = events
        webServer.log = { print("Web Server:", $0) }
        webServer.update = {
            DispatchQueue.global(qos: .userInitiated).async {
                #if os(Linux)
                system("/opt/colemancda/lockd/update.sh")
                #else
                print("Simulate software update")
                #endif
            }
        }
        */
        
        // load hardware configuration
        if let hardware = try? JSONDecoder().decode(LockHardware.self, from: URL(fileURLWithPath: "/opt/colemancda/lockd/hardware.json")) {
            
            print("Running on hardware:")
            dump(hardware)
            
            await controller?.setHardware(hardware)
            //webServer.hardware = hardware
            
            // load GPIO
            if let gpioController = hardware.gpioController() {
                print("Loaded GPIO Controller: \(type(of: gpioController))")
                controller?.lockServiceController.unlockDelegate = gpioController
                gpio = gpioController
                gpioController.didPressResetButton = {
                    print("Reset Button pressed at \(Date())")
                    Task { await controller?.lockServiceController.reset() }
                }
            }
        }
        
        // publish GATT server, enable advertising
        try await peripheral.start()
        
        // configure custom advertising
        try await hostController?.setLockAdvertisingData(lock: lockIdentifier, rssi: 30) // FIXME: RSSI
        try await hostController?.setLockScanResponse()
        try await hostController?.writeLocalName("Lock")
                
        controller?.lockServiceController.lockChanged = lockChanged
        //webServer.lockChanged = lockChanged
        
        // make sure the device is always discoverable
        Task.detached {
            while controller != nil {
                try await Task.sleep(nanoseconds: 30 * 1_000_000_000)
                do { try await hostController?.enableLowEnergyAdvertising() }
                catch HCIError.commandDisallowed { } // already enabled
                catch {
                    print("Unable to enable advertising")
                    dump(error)
                }
            }
        }
    }
    
    // change advertisment for notifications
    private static func lockChanged() {
        guard let hostController = self.hostController else {
            return
        }
        Task.detached {
            do {
                try await hostController.setNotificationAdvertisement(rssi: 30) // FIXME: RSSI
                try await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                try await hostController.setLockAdvertisingData(lock: id, rssi: 30)
            }
            catch {
                print("Unable to change advertising")
                dump(error)
            }
        }
    }
}
