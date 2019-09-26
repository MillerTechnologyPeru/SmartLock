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
        
        guard let lockIdentifier = self.lockIdentifier
            else { assertionFailure(); return }
        
        // request name
        requestNewKeyName { (newKeyName) in
            
            let newKeyIdentifier = UUID()
            
            guard let lockCache = Store.shared[lock: lockIdentifier],
                let parentKeyData = Store.shared[key: lockCache.key.identifier]
                else { self.newKeyError(R.string.localizable.newKeyViewControllerErrorRequestNewKey()); return }
            
            let parentKey = KeyCredentials(identifier: lockCache.key.identifier, secret: parentKeyData)
            
            log("Setting up new key for lock \(lockIdentifier)")
            
            self.showActivity()
            
            // add new key to lock
            DispatchQueue.bluetooth.async { [weak self] in
                
                guard let self = self else { return }
                
                let newKey = NewKey(
                    identifier: newKeyIdentifier,
                    name: newKeyName,
                    permission: permission
                )
                
                let newKeySharedSecret = KeyData()
                
                let newKeyInvitation = NewKey.Invitation(
                    lock: lockIdentifier,
                    key: newKey,
                    secret: newKeySharedSecret
                )
                
                do {
                    guard let peripheral = try Store.shared.device(for: lockIdentifier, scanDuration: 2.0) else {
                        mainQueue {
                            self.hideActivity(animated: false)
                            self.newKeyError(R.string.localizable.newKeyViewControllerErrorLockInRange())
                        }
                        return
                    }
                    try LockManager.shared.createKey(
                        .init(key: newKey, secret: newKeySharedSecret),
                        for: peripheral.scanData.peripheral,
                        with: parentKey)
                }
                    
                catch {
                    mainQueue {
                        self.hideActivity(animated: false)
                        self.newKeyError(R.string.localizable.newKeyViewControllerErrorCreateNewKey(error.localizedDescription))
                    }
                    return
                }
                
                log("Created new key \(newKey.identifier) (\(newKey.permission.type))")
                
                mainQueue { completion(newKeyInvitation) }
            }
        }
    }
    
    private func requestNewKeyName(_ completion: @escaping (String) -> ()) {
        
        let alert = UIAlertController(title: R.string.localizable.newKeyViewControllerNewKeyTitle(),
                                      message: R.string.localizable.newKeyViewControllerNewKeyMessage(),
                                      preferredStyle: .alert)
        
        alert.addTextField { $0.text = R.string.localizable.newKeyViewControllerNewKeyTitle() }
        
        alert.addAction(UIAlertAction(title: R.string.localizable.newKeyViewControllerNewKeyOk(), style: .`default`, handler: { (UIAlertAction) in
            
            let name = alert.textFields![0].text ?? ""
            
            completion(name)
            
            alert.dismiss(animated: true) {  }
            
        }))
        
        alert.addAction(UIAlertAction(title: R.string.localizable.newKeyViewControllerNewKeyCancel(), style: .destructive, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) {  }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func newKeyError(_ error: String) {
        
        self.showErrorAlert(error, okHandler: { self.dismiss(animated: true, completion: nil) }, retryHandler: nil)
    }
}

public extension UIViewController {
    
    /// Share invitation via action sheet
    func share(invitation: NewKey.Invitation,
               sender: PopoverPresentingView,
               completion: @escaping () -> ()) {
        
        DispatchQueue.app.async {
            
            // save invitation file
            let newKeyData = try! JSONEncoder().encode(invitation)
            
            let filePath = try! FileManager.default
                .url(for: .cachesDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("newKey-\(invitation.key.identifier).ekey")
                .path
            
            guard FileManager.default.createFile(atPath: filePath, contents: newKeyData, attributes: nil)
                else { assertionFailure("Could not write \(filePath) to disk"); return }
            
            // share new key
            mainQueue {
                                
                // show activity controller
                let activityController = UIActivityViewController(
                    activityItems: [
                        URL(fileURLWithPath: filePath),
                        invitation
                    ],
                    applicationActivities: [
                        ShareKeyCloudKitActivity()
                    ]
                )
                
                activityController.excludedActivityTypes = [.postToTwitter,
                                                            .postToFacebook,
                                                            .postToWeibo,
                                                            .postToTencentWeibo,
                                                            .postToFlickr,
                                                            .postToVimeo,
                                                            .print,
                                                            .assignToContact,
                                                            .saveToCameraRoll,
                                                            .addToReadingList]
                
                activityController.completionWithItemsHandler = { (activityType, completed, items, error) in
                    
                    self.dismiss(animated: true, completion: nil)
                    completion()
                }
                
                self.present(activityController, animated: true, completion: nil, sender: sender)
            }
        }
    }
}
