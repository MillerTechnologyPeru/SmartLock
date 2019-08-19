//
//  ActivityHandling.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/18/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock
import UIKit
import QRCodeReader

protocol LockActivityHandling {
    
    func handle(url: LockURL)
    
    func handle(activity: AppActivity)
}

// MARK: - View Controller

protocol LockActivityHandlingViewController: class, LockActivityHandling { }

extension LockActivityHandlingViewController where Self: UIViewController, Self: ActivityIndicatorViewController {
    
    func handle(url: LockURL) {
        
        switch url {
        case let .setup(lock: identifier, secret: secret):
            self.setup(lock: identifier, secret: secret)
        case let .unlock(lock: identifier):
            self.unlock(lock: identifier)
        case let .newKey(invitation):
            self.open(newKey: invitation)
        }
    }
    
    func handle(activity: AppActivity) {
        
        
    }
}

extension ActivityIndicatorViewController where Self: UIViewController {
    
    func setup(lock: LockPeripheral<NativeCentral>) {
        
        // scan QR code
        precondition(QRCodeReader.isAvailable(), "QR Code Reader not supported")
        
        let readerViewController: QRCodeReaderViewController = {
            let builder = QRCodeReaderViewControllerBuilder {
                $0.reader = QRCodeReader(
                    metadataObjectTypes: [.qr],
                    captureDevicePosition: .back
                )
            }
            return QRCodeReaderViewController(builder: builder)
        }()
        
        readerViewController.completionBlock = { [unowned self] (result: QRCodeReaderResult?) in
            
            readerViewController.dismiss(animated: true, completion: {
                
                // did not scan
                guard let result = result else { return }
                
                guard let url = URL(string: result.value),
                    let lockURL = LockURL(rawValue: url),
                    case let .setup(_, sharedSecret) = lockURL else {
                        self.showErrorAlert("Invalid QR code")
                        return
                }
                
                // perform BLE request
                self.setup(lock: lock, sharedSecret: sharedSecret)
            })
        }
        
        // Presents the readerVC as modal form sheet
        readerViewController.modalPresentationStyle = .formSheet
        present(readerViewController, animated: true, completion: nil)
    }
    
    func setup(lock identifier: UUID, secret: KeyData, name: String = "Lock", scanDuration: TimeInterval = 2.0) {
        
        performActivity(showProgressHUD: true, { () -> Bool in
            guard let lockPeripheral = try Store.shared.device(for: identifier, scanDuration: scanDuration)
                else { return false }
            try Store.shared.setup(lockPeripheral, sharedSecret: secret, name: name)
            return true
        }, completion: { (viewController, foundDevice) in
            if foundDevice == false {
                viewController.showErrorAlert("Could not lock")
            }
        })
    }
    
    func setup(lock: LockPeripheral<NativeCentral>, sharedSecret: KeyData, name: String = "Lock") {
        
        performActivity({ try Store.shared.setup(lock, sharedSecret: sharedSecret, name: name) })
    }
    
    func unlock(lock identifier: UUID, action: UnlockAction = .default,  scanDuration: TimeInterval = 2.0) {
        
        let oldActivity = self.userActivity
        self.userActivity = NSUserActivity(.action(.unlock(identifier)))
        self.userActivity?.becomeCurrent()
        
        performActivity(showProgressHUD: true, { () -> String? in
            guard let lockPeripheral = try Store.shared.device(for: identifier, scanDuration: scanDuration)
                else { return "Could not find lock" }
            return try Store.shared.unlock(lockPeripheral, action: action) ? nil : "Unable to unlock"
        }, completion: { (viewController, errorMessage) in
            if let errorMessage = errorMessage {
                viewController.showErrorAlert(errorMessage)
            }
            viewController.userActivity?.resignCurrent()
            viewController.userActivity = oldActivity
        })
    }
    
    func unlock(lock: LockPeripheral<NativeCentral>, action: UnlockAction = .default) {
        
        let oldActivity = self.userActivity
        if let lockInformation = Store.shared.lockInformation.value[lock.scanData.peripheral] {
            self.userActivity = NSUserActivity(.action(.unlock(lockInformation.identifier)))
            self.userActivity?.becomeCurrent()
        }
        
        performActivity({
            try Store.shared.unlock(lock, action: action)
        }, completion: { (viewController, _) in
            self.userActivity?.resignCurrent()
            self.userActivity = oldActivity
        })
    }
}
