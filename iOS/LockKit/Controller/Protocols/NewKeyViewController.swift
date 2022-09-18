//
//  NewKeyViewController.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 7/10/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreLock

public protocol NewKeyViewController: ActivityIndicatorViewController {
    
    var lockIdentifier: UUID! { get }
    
    var view: UIView! { get }
    
    func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> ())?)
    
    func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> ())?, sender: PopoverPresentingView)
    
    func dismiss(animated: Bool, completion: (() -> ())?)
    
    func showErrorAlert(_ localizedText: String, okHandler: (() -> ())?, retryHandler: (()-> ())?)
}

public extension NewKeyViewController {
    
    func newKey(permission: Permission,
                completion: @escaping (NewKey.Invitation) -> ()) {
        
        guard let lockIdentifier = self.lockIdentifier,
            let lockCache = Store.shared[lock: lockIdentifier],
            let parentKeyData = Store.shared[key: lockCache.key.id]
            else { assertionFailure(); return }
        
        // request name
        requestNewKeyName { (newKeyName) in
            
            let newKeyIdentifier = UUID()
            
            let parentKey = KeyCredentials(id: lockCache.key.id, secret: parentKeyData)
            
            log("Setting up new key for lock \(lockIdentifier)")
            
            self.showActivity()
            
            // add new key to lock
            Task {
                                
                let newKey = NewKey(
                    id: newKeyIdentifier,
                    name: newKeyName,
                    permission: permission
                )
                
                let newKeySharedSecret = KeyData()
                
                // file for sharing
                let newKeyInvitation = NewKey.Invitation(
                    lock: lockIdentifier,
                    key: newKey,
                    secret: newKeySharedSecret
                )
                
                // for BLE / HTTP request
                let newKeyRequest = CreateNewKeyRequest(key: newKey, secret: newKeySharedSecret)
                
                do {
                    // first try via BLE
                    if await Store.shared.central.state == .poweredOn,
                       let peripheral = try await Store.shared.device(for: lockIdentifier, scanDuration: 2.0) {
                        
                        try await Store.shared.central.createKey(
                            newKeyRequest,
                            using: parentKey,
                            for: peripheral
                        )
                        
                    } /*else if let netService = try Store.shared.netServiceClient.discover(duration: 1.0, timeout: 10.0).first(where: { $0.id == lockIdentifier }) {
                        
                        // try via Bonjour
                        try Store.shared.netServiceClient.createKey(
                            newKeyRequest,
                            for: netService,
                            with: parentKey,
                            timeout: 30.0
                        )
                        
                    } */ else {
                        // not in range
                        mainQueue {
                            self.hideActivity(animated: false)
                            self.newKeyError(R.string.error.notInRange())
                        }
                        return
                    }
                    
                }
                catch {
                    mainQueue {
                        #if DEBUG
                        dump(error)
                        #endif
                        self.hideActivity(animated: false)
                        self.newKeyError(error.localizedDescription)
                    }
                    return
                }
                
                log("Created new key \(newKey.id) (\(newKey.permission.type))")
                mainQueue { completion(newKeyInvitation) }
            }
        }
    }
    
    private func requestNewKeyName(_ completion: @escaping (String) -> ()) {
        
        let alert = UIAlertController(
            title: R.string.newKeyViewController.alertNewKeyTitle(),
            message: R.string.newKeyViewController.alertNewKeyMessage(),
            preferredStyle: .alert
        )
        
        alert.addTextField { $0.text = R.string.newKeyViewController.alertNewKeyTitle() }
        
        alert.addAction(UIAlertAction(title: R.string.localizable.alertOk(), style: .`default`, handler: { (UIAlertAction) in
            
            let name = alert.textFields![0].text ?? ""
            
            completion(name)
            
            alert.dismiss(animated: true) {  }
            
        }))
        
        alert.addAction(UIAlertAction(title: R.string.localizable.alertCancel(), style: .destructive, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) {  }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func newKeyError(_ error: String) {
        
        log("⚠️ Unable to share key. \(error)")
        self.showErrorAlert(error, okHandler: { self.dismiss(animated: true, completion: nil) }, retryHandler: nil)
    }
}

public extension UIViewController {
    
    /// Share invitation via action sheet
    func share(invitation: NewKey.Invitation,
               sender: PopoverPresentingView,
               completion: @escaping () -> ()) {
        
        // show activity controller
        let activityController = UIActivityViewController(
            activityItems: [
                NewKeyFileActivityItem(invitation: invitation),
                invitation
            ],
            applicationActivities: [
                ShareKeyCloudKitActivity()
            ]
        )
        activityController.excludedActivityTypes = NewKeyFileActivityItem.excludedActivityTypes
        activityController.completionWithItemsHandler = { (activityType, completed, items, error) in
            self.dismiss(animated: true, completion: nil)
            completion()
        }
        
        self.present(activityController, animated: true, completion: nil, sender: sender)
    }
}
