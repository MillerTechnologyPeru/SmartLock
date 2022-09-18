//
//  Central.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

#if canImport(CoreBluetooth) && canImport(DarwinGATT)
import Foundation
import CoreBluetooth
import Bluetooth
import GATT
import DarwinGATT

public typealias NativeCentral = DarwinCentral
public typealias NativePeripheral = DarwinCentral.Peripheral
#endif
