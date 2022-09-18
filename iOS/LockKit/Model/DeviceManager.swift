//
//  DeviceManager.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import Bluetooth
import GATT
import CoreLock

#if canImport(CoreBluetooth) && canImport(DarwinGATT)
import CoreBluetooth
import DarwinGATT

public typealias NativeCentral = DarwinCentral
#endif
