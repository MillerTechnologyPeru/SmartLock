//
//  NewKeyViewController.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 7/10/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import Foundation
import CoreLock

protocol NewKeyViewController: ActivityIndicatorViewController {
    
    var lockIdentifier: UUID! { get }
    
    var view: UIView! { get }
    
    func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> ())?)
    
    func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> ())?, sender: PopoverPresentingView)
    
    func dismiss(animated: Bool, completion: (() -> ())?)
    
    func showErrorAlert(_ localizedText: String, okHandler: (() -> ())?, retryHandler: (()-> ())?)
}

extension NewKeyViewController {
    
    func newKey(permission: Permission, sender: PopoverPresentingView) {
        
        let lockIdentifier = self.lockIdentifier!
        
        // request name
        requestNewKeyName { (newKeyName) in
            
            let newKeyIdentifier = UUID()
            
            guard let lockCache = Store.shared[lock: lockIdentifier],
                let parentKeyData = Store.shared[key: lockCache.key.identifier]
                else { self.newKeyError("The key for the specified lock has been deleted from the database."); return }
            
            guard let peripheral = Store.shared[peripheral: lockIdentifier]
                else { self.newKeyError("Please scan for the device first."); return }
            
            let parentKey = KeyCredentials(identifier: lockCache.key.identifier, secret: parentKeyData)
            
            print("Setting up new key for lock \(lockIdentifier)")
            
            self.showProgressHUD()
            
            // add new key to lock
            async {
                
                let newKey = NewKey(
                    identifier: newKeyIdentifier,
                    name: newKeyName,
                    permission: permission)
                
                let newKeySharedSecret = KeyData()
                
                let newKeyInvitation = NewKey.Invitation(
                    lock: lockIdentifier,
                    key: newKey,
                    secret: newKeySharedSecret
                )
                
                do {
                    try LockManager.shared.createKey(.init(key: newKey, secret: newKeySharedSecret),
                                                     for: peripheral,
                                                     with: parentKey)
                }
                    
                catch {
                    mainQueue {
                        self.dismissProgressHUD(animated: false)
                        self.newKeyError("Could not create new key. (\(error))")
                    }
                    return
                }
                
                print("Created new key \(newKey.identifier) (\(newKey.permission.type))")
                
                // save invitation file
                
                let newKeyData = try! JSONEncoder().encode(newKeyInvitation)
                
                let filePath = try! FileManager.default
                    .url(for: .cachesDirectory,
                         in: .userDomainMask,
                         appropriateFor: nil,
                         create: true)
                    .appendingPathComponent("newKey-\(newKey.identifier).ekey")
                    .path
                
                guard FileManager.default.createFile(atPath: filePath, contents: newKeyData, attributes: nil)
                    else { fatalError("Could not write \(filePath) to disk") }
                
                // share new key
                mainQueue {
                    
                    self.dismissProgressHUD()
                    
                    // show activity controller
                    let activityController = UIActivityViewController(activityItems: [URL(fileURLWithPath: filePath)], applicationActivities: nil)
                    
                    activityController.excludedActivityTypes = [.postToTwitter,
                                                                .postToFacebook,
                                                                .postToWeibo,
                                                                .print,
                                                                .copyToPasteboard,
                                                                .assignToContact,
                                                                .saveToCameraRoll,
                                                                .addToReadingList,
                                                                .postToFlickr,
                                                                .postToVimeo,
                                                                .postToTencentWeibo]
                    
                    activityController.completionWithItemsHandler = { (activityType, completed, items, error) in
                        
                        self.dismiss(animated: true, completion: nil)
                    }
                    
                    self.present(activityController, animated: true, completion: nil, sender: sender)
                }
            }
        }
    }
    
    private func requestNewKeyName(_ completion: @escaping (String) -> ()) {
        
        let alert = UIAlertController(title: "New Key",
                                      message: "Type a user friendly name for the new key.",
                                      preferredStyle: .alert)
        
        alert.addTextField { $0.text = "New Key" }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .`default`, handler: { (UIAlertAction) in
            
            let name = alert.textFields![0].text ?? ""
            
            completion(name)
            
            alert.dismiss(animated: true) {  }
            
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .destructive, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) {  }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func newKeyError(_ error: String) {
        
        self.showErrorAlert(error, okHandler: { self.dismiss(animated: true, completion: nil) }, retryHandler: nil)
    }
}
