//
//  Setup.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/19/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreLock

#if canImport(QRCodeReader)
import QRCodeReader

public extension ActivityIndicatorViewController where Self: UIViewController {
    
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
}
#endif

public extension ActivityIndicatorViewController where Self: UIViewController {
    
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
}
