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

#if os(iOS) && !targetEnvironment(macCatalyst)
import QRCodeReader

public extension ActivityIndicatorViewController where Self: UIViewController {
    
    func setup(lock: NativeCentral.Peripheral) {
        
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
                        self.showErrorAlert(R.string.error.invalidQRCode())
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
    
    func setup(lock id: UUID, secret: KeyData, name: String? = nil, scanDuration: TimeInterval = 2.0) {
        
        let name = name ?? R.string.localizable.newLockName()
        performActivity({
            guard let lockPeripheral = try await Store.shared.device(for: id, scanDuration: scanDuration)
                else { return false }
            try await Store.shared.setup(lockPeripheral, sharedSecret: secret, name: name)
            return true
        }, completion: { (viewController, foundDevice) in
            if foundDevice == false {
                viewController.showErrorAlert(R.string.error.notInRange())
            }
        })
    }
    
    func setup(lock: NativeCentral.Peripheral, sharedSecret: KeyData, name: String? = nil) {
        
        let name = name ?? R.string.localizable.newLockName()
        performActivity({
            try await Store.shared.setup(lock, sharedSecret: sharedSecret, name: name)
        })
    }
}
