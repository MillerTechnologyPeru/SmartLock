//
//  TodayViewController.swift
//  Today
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import NotificationCenter
import CoreBluetooth
import Bluetooth
import GATT
import DarwinGATT
import CoreLock
import LockKit

final class TodayViewController: UIViewController, NCWidgetProviding {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        log("☀️ Loaded \(TodayViewController.self)")
        
        // Set Logging
        LockManager.shared.log = { log("🔒 \(LockManager.self): " + $0) }
        BeaconController.shared.log = { log("📶 \(BeaconController.self): " + $0) }
        
        
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
}
