//
//  Activity.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 7/3/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreLock
import JGProgressHUD

public struct LockActivityItem {
    
    public static let excludedActivityTypes: [UIActivity.ActivityType] = [
        .print,
        .assignToContact,
        .airDrop,
        .copyToPasteboard,
        .saveToCameraRoll,
        .postToFlickr,
        .postToVimeo,
        .addToReadingList,
        .assignToContact,
        .postToTencentWeibo,
        .postToWeibo,
        .openInIBooks,
        .markupAsPDF
    ]
    
    public let identifier: UUID
    
    public init(identifier: UUID) {
        
        self.identifier = identifier
    }
    
    // MARK: - Activity Values
    
    public var text: String {
        
        guard let lockCache = Store.shared[lock: identifier]
            else { fatalError("Lock not in cache") }
        
        return R.string.localizable.lockActivityItemText(lockCache.name)
    }
    
    public var image: UIImage {
        
        guard let lockCache = Store.shared[lock: identifier]
            else { fatalError("Lock not in cache") }
        
        return UIImage(permission: lockCache.key.permission)
    }
}

/// `UIActivity` types
public enum LockActivity: String {
    
    case newKey =               "com.colemancda.lock.activity.newKey"
    case manageKeys =           "com.colemancda.lock.activity.manageKeys"
    case delete =               "com.colemancda.lock.activity.delete"
    case rename =               "com.colemancda.lock.activity.rename"
    case update =               "com.colemancda.lock.activity.update"
    case homeKitEnable =        "com.colemancda.lock.activity.homeKitEnable"
    case addVoiceShortcut =     "com.colemancda.lock.activity.addVoiceShortcut"
    case shareKeyCloudKit =     "com.colemancda.lock.activity.shareKeyCloudKit"
    
    var activityType: UIActivity.ActivityType {
        return UIActivity.ActivityType(rawValue: self.rawValue)
    }
}

/// Activity for sharing a key.
public final class NewKeyActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.newKey.activityType
    }
    
    public override var activityTitle: String? {
        return R.string.localizable.newKeyActivityTitle()
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityNewKey()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        guard let lockItem = activityItems.first as? LockActivityItem,
            let lockCache = Store.shared[lock: lockItem.identifier],
            Store.shared[peripheral: lockItem.identifier] != nil // Lock must be reachable
            else { return false }
        
        // only owner and admin can share keys
        return lockCache.key.permission.isAdministrator
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        self.item = activityItems.first as? LockActivityItem
    }
    
    public override var activityViewController: UIViewController? {
        
        let viewController = NewKeySelectPermissionViewController.fromStoryboard(with: item.identifier)
        viewController.completion =  { [unowned self] in
            guard let (invitation, sender) = $0 else {
                self.activityDidFinish(false)
                return
            }
            // show share sheet
            viewController.share(invitation: invitation, sender: sender) { [unowned self] in
                self.activityDidFinish(true)
            }
        }
        
        return UINavigationController(rootViewController: viewController)
    }
}

/// Activity for managing keys of a lock.
public final class ManageKeysActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.manageKeys.activityType
    }
    
    public override var activityTitle: String? {
        return R.string.localizable.manageKeysActivityTitle()
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityManageKeys()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        guard let lockItem = activityItems.first as? LockActivityItem,
            let lockCache = Store.shared[lock: lockItem.identifier],
            Store.shared[peripheral: lockItem.identifier] != nil // Lock must be reachable
            else { return false }
        
        return lockCache.key.permission.isAdministrator
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        self.item = activityItems.first as? LockActivityItem
    }
    
    public override var activityViewController: UIViewController? {
        
        let viewController = LockPermissionsViewController.fromStoryboard(
            with: item.identifier,
            completion: { [weak self] in self?.activityDidFinish(true) }
        )
        
        return UINavigationController(rootViewController: viewController)
    }
}

/// Activity for deleting the lock locally.
public final class DeleteLockActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    /// Called when lock deleted.
    public var completion: (() -> ())?
    
    public convenience init(completion: (() -> ())?) {
        
        self.init()
        self.completion = completion
    }
    
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.delete.activityType
    }
    
    public override var activityTitle: String? {
        return R.string.localizable.deleteLockActivityTitle()
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityDelete()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return activityItems.first as? LockActivityItem != nil
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        self.item = activityItems.first as? LockActivityItem
    }
    
    public override var activityViewController: UIViewController? {
        
        return type(of: self).viewController(for: item.identifier, completion: { [weak self] (didDelete) in
            self?.activityDidFinish(didDelete)
            if didDelete { self?.completion?() }
        })
    }
    
    public static func viewController(for lock: UUID, completion: @escaping (Bool) -> ()) -> UIAlertController {
        
        let alert = UIAlertController(
            title: R.string.localizable.deleteLockActivityAlertTitle(),
            message: R.string.localizable.deleteLockActivityAlertMessage(),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: R.string.localizable.deleteLockActivityAlertCancel(), style: .cancel, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) { completion(false) }
        }))
        
        alert.addAction(UIAlertAction(title: R.string.localizable.deleteLockActivityAlertDelete(), style: .destructive, handler: { (UIAlertAction) in
            
            Store.shared.remove(lock)
            
            alert.dismiss(animated: true) {
                completion(true)
            }
        }))
        
        return alert
    }
}

/// Activity for renaming a lock.
public final class RenameActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.rename.activityType
    }
    
    public override var activityTitle: String? {
        return R.string.localizable.renameActivityTitle()
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityRename()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return activityItems.first as? LockActivityItem != nil
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        self.item = activityItems.first as? LockActivityItem
    }
    
    public override var activityViewController: UIViewController? {
        return type(of: self).viewController(for: item.identifier, completion: { [weak self] in
            self?.activityDidFinish($0)
        })
    }
    
    public static func viewController(for lock: UUID,
                                      completion: @escaping (Bool) -> ()) -> UIAlertController {
        
        let alert = UIAlertController(title: R.string.localizable.renameActivityAlertTitle(),
                                      message: R.string.localizable.renameActivityAlertMessage(),
                                      preferredStyle: .alert)
        
        alert.addTextField { $0.text = Store.shared[lock: lock]?.name }
        
        alert.addAction(UIAlertAction(title: R.string.localizable.renameActivityAlertOK(), style: .`default`, handler: { (UIAlertAction) in
            
            Store.shared[lock: lock]?.name = alert.textFields?[0].text ?? ""
            alert.dismiss(animated: true) { completion(true) }
        }))
        
        alert.addAction(UIAlertAction(title: R.string.localizable.renameActivityAlertCancel(), style: .destructive, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) { completion(false) }
        }))
        
        return alert
    }
}

/// Activity for enabling HomeKit.
public final class HomeKitEnableActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.homeKitEnable.activityType
    }
    
    public override var activityTitle: String? {
        return R.string.localizable.homeKitEnableActivityTitle()
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityHomeKit()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        guard let lockItem = activityItems.first as? LockActivityItem,
            let lockCache = Store.shared[lock: lockItem.identifier],
            Store.shared[peripheral: lockItem.identifier] != nil // Lock must be reachable
            else { return false }
        
        guard lockCache.key.permission == .owner
            else { return false }
        
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        
        self.item = activityItems.first as? LockActivityItem
    }
    
    public override var activityViewController: UIViewController? {
        
        let lockItem = self.item!
        
        let alert = UIAlertController(title: R.string.localizable.homeKitEnableActivityAlertTitle(),
                                      message: R.string.localizable.homeKitEnableActivityAlertMessage(),
                                      preferredStyle: .alert)
        
        func enableHomeKit(_ enable: Bool = true) {
            
            guard let lockItem = self.item,
                let lockCache = Store.shared[lock: lockItem.identifier],
                let keyData = Store.shared[key: lockCache.key.identifier],
                let peripheral = Store.shared[peripheral: lockItem.identifier] // Lock must be reachable
                else { alert.dismiss(animated: true) { self.activityDidFinish(false) }; return }
            
            DispatchQueue.bluetooth.async {
                
                //do { try LockManager.shared.enableHomeKit(lockItem.identifier, key: (lockCache.keyIdentifier, keyData), enable: enable) }
                
                //catch { mainQueue { alert.showErrorAlert("\(error)"); self.activityDidFinish(false) }; return }
                
                mainQueue { alert.dismiss(animated: true) { self.activityDidFinish(true) } }
            }
        }
            
        alert.addAction(UIAlertAction(title:R.string.localizable.homeKitEnableActivityAlertCancel(), style: .cancel, handler: { (UIAlertAction) in
                        
            alert.dismiss(animated: true) { self.activityDidFinish(false) }
        }))
        
        alert.addAction(UIAlertAction(title: R.string.localizable.homeKitEnableActivityAlertYes(), style: .`default`, handler: { (UIAlertAction) in
            
            enableHomeKit()
        }))
        
        alert.addAction(UIAlertAction(title: R.string.localizable.homeKitEnableActivityAlertNo(), style: .`default`, handler: { (UIAlertAction) in
            
            enableHomeKit(false)
        }))
        
        return alert
    }
}

public final class UpdateActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.homeKitEnable.activityType
    }
    
   public  override var activityTitle: String? {
        return R.string.localizable.updateActivityTitle()
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityUpdate()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        guard let lockItem = activityItems.first as? LockActivityItem,
            let lockCache = Store.shared[lock: lockItem.identifier],
            Store.shared[peripheral: lockItem.identifier] != nil // Lock must be reachable
            else { return false }
        
        guard lockCache.key.permission == .owner
            else { return false }
        
        return true
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        
        self.item = activityItems.first as? LockActivityItem
    }
    
    public override var activityViewController: UIViewController? {
        
        //let lockItem = self.item!
        
        let alert = UIAlertController(title: R.string.localizable.updateActivityAlertTitle(),
                                      message: R.string.localizable.updateActivityAlertMessage(),
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: R.string.localizable.updateActivityAlertCancel(), style: .cancel, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) { self.activityDidFinish(false) }
        }))
        
        alert.addAction(UIAlertAction(title: R.string.localizable.updateActivityAlertUpdate(), style: .`default`, handler: { (UIAlertAction) in
            /*
            let progressHUD = JGProgressHUD(style: .dark)!
            
            func showProgressHUD() {
                
                progressHUD.show(in: alert.view)
                
                alert.view.isUserInteractionEnabled = false
            }
            
            func dismissProgressHUD(_ animated: Bool = true) {
                
                progressHUD.dismiss()
                
                alert.view.isUserInteractionEnabled = true
            }
            
            // fetch cache
            guard let (lockCache, keyData) = Store.shared[lockItem.identifier]
                else { alert.dismiss(animated: true) { self.activityDidFinish(false) }; return }
            
            showProgressHUD()
            
            async {
                
                do { try LockManager.shared.update(lockItem.identifier, key: (lockCache.keyIdentifier, keyData)) }
                    
                catch { mainQueue { dismissProgressHUD(false); alert.showErrorAlert("\(error)"); self.activityDidFinish(false) }; return }
                
                mainQueue { dismissProgressHUD(); alert.dismiss(animated: true) { self.activityDidFinish(true) } }
            }*/
        }))
        
        return alert
    }
}

public final class ShareKeyCloudKitActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .share }
     
    internal private(set) var invitation: NewKey.Invitation?
     
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.shareKeyCloudKit.activityType
    }
     
    public  override var activityTitle: String? {
         return R.string.localizable.shareKeyCloudKitActivityTitle()
     }
     
     public override var activityImage: UIImage? {
         return UIImage(named: "AppIcon")
     }
     
     public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for case is NewKey.Invitation in activityItems {
            return true
        }
        return false
     }
     
     public override func prepare(withActivityItems activityItems: [Any]) {
        for case let invitation as NewKey.Invitation in activityItems {
            self.invitation = invitation
            return
        }
     }
     
    public override var activityViewController: UIViewController? {
        
        guard let invitation = self.invitation else {
            assertionFailure()
            return nil
        }
        
        let viewController = ContactsViewController.fromStoryboard()
        viewController.didSelect = { (contact) in
            let progressHUD = JGProgressHUD.currentStyle(for: viewController)
            progressHUD.show(in: viewController.navigationController?.view ?? viewController.view)
            DispatchQueue.app.async { [weak self] in
                do {
                    try Store.shared.cloud.share(invitation, to: contact)
                    mainQueue {
                        progressHUD.dismiss(animated: true)
                        self?.activityDidFinish(true)
                    }
                }
                catch {
                    mainQueue {
                        progressHUD.dismiss(animated: false)
                        viewController.showErrorAlert(error.localizedDescription, okHandler: {
                            self?.activityDidFinish(false)
                        })
                    }
                }
            }
        }
        return UINavigationController(rootViewController: viewController)
    }
}

#if canImport(IntentsUI)
import IntentsUI

public final class AddVoiceShortcutActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.addVoiceShortcut.activityType
    }
    
    public  override var activityTitle: String? {
        return R.string.localizable.addVoiceShortcutActivityTitle()
    }
    
    public override var activityImage: UIImage? {
        return R.image.activitySiri()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        #if targetEnvironment(macCatalyst)
        return false
        #else
        guard #available(iOS 12, *)
            else { return false }
        
        guard let lockItem = activityItems.first as? LockActivityItem,
            let _ = Store.shared[lock: lockItem.identifier]
            else { return false }
        
        return true
        #endif
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        self.item = activityItems.first as? LockActivityItem
    }
    
    public override var activityViewController: UIViewController? {
        
        #if targetEnvironment(macCatalyst)
        return nil
        #else
        guard #available(iOS 12, *)
            else { return nil }
        
        guard let lockItem = self.item
            else { fatalError() }
        
        guard let lockCache = Store.shared[lock: lockItem.identifier]
            else { assertionFailure("Invalid lock"); return nil }
        
        let intent = UnlockIntent(identifier: lockItem.identifier, cache: lockCache)
        let shortcut = INShortcut.intent(intent)
        let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        viewController.modalPresentationStyle = .formSheet
        viewController.delegate = self
        return viewController
        #endif
    }
}

// MARK: - INUIAddVoiceShortcutViewControllerDelegate

@available(iOS 12, *)
extension AddVoiceShortcutActivity: INUIAddVoiceShortcutViewControllerDelegate {
    
    public func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    public func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}


#endif
