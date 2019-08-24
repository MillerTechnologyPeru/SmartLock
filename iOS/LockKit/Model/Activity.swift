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
        .openInIBooks]
    
    public let identifier: UUID
    
    public init(identifier: UUID) {
        
        self.identifier = identifier
    }
    
    // MARK: - Activity Values
    
    public var text: String {
        
        guard let lockCache = Store.shared[lock: identifier]
            else { fatalError("Lock not in cache") }
        
        return "I unlocked my door \"\(lockCache.name)\""
    }
    
    public var image: UIImage {
        
        guard let lockCache = Store.shared[lock: identifier]
            else { fatalError("Lock not in cache") }
        
        return UIImage(permission: lockCache.key.permission)
    }
}

/// `UIActivity` types
public enum LockActivity: String {
    
    case newKey = "com.colemancda.lock.activity.newKey"
    case manageKeys = "com.colemancda.lock.activity.manageKeys"
    case delete = "com.colemancda.lock.activity.delete"
    case rename = "com.colemancda.lock.activity.rename"
    case update = "com.colemancda.lock.activity.update"
    case homeKitEnable = "com.colemancda.lock.activity.homeKitEnable"
    case addVoiceShortcut = "com.colemancda.lock.activity.addVoiceShortcut"
    
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
        return "Share Key"
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityNewKey()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        guard let lockItem = activityItems.first as? LockActivityItem,
            let lockCache = Store.shared[lock: lockItem.identifier],
            Store.shared[peripheral: lockItem.identifier] != nil // Lock must be reachable
            else { return false }
        
        return lockCache.key.permission.canShareKeys
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        
        self.item = activityItems.first as? LockActivityItem
    }
    
    public override var activityViewController: UIViewController? {
        
        let navigationController = UIStoryboard(name: "NewKey", bundle: .lockKit).instantiateInitialViewController() as! UINavigationController
        
        let destinationViewController = navigationController.viewControllers.first! as! NewKeySelectPermissionViewController
        destinationViewController.lockIdentifier = item.identifier
        destinationViewController.completion = { [unowned self] in
            guard let (invitation, sender) = $0 else {
                self.activityDidFinish(false)
                return
            }
            // show share sheet
            destinationViewController.share(invitation: invitation, sender: sender) { [unowned self] in
                self.activityDidFinish(true)
            }
        }
        
        return navigationController
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
        return "Manage"
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityManageKeys()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        guard let lockItem = activityItems.first as? LockActivityItem,
            let lockCache = Store.shared[lock: lockItem.identifier],
            Store.shared[peripheral: lockItem.identifier] != nil // Lock must be reachable
            else { return false }
        
        switch lockCache.key.permission {
        case .owner,
             .admin:
            return true
        case .anytime,
             .scheduled:
            return false
        }
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        
        self.item = activityItems.first as? LockActivityItem
    }
    
    public override var activityViewController: UIViewController? {
        
        let navigationController = UIStoryboard(name: "LockPermissions", bundle: .lockKit).instantiateInitialViewController() as! UINavigationController
        
        let destinationViewController = navigationController.viewControllers.first! as! LockPermissionsViewController
        destinationViewController.lockIdentifier = item.identifier
        destinationViewController.completion = { self.activityDidFinish(true) }
        
        return navigationController
    }
}

/// Activity for deleting the lock locally.
public final class DeleteLockActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.delete.activityType
    }
    
    public override var activityTitle: String? {
        return "Delete"
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
        
        let alert = UIAlertController(title: NSLocalizedString("Confirmation", comment: "DeletionConfirmation"),
                                      message: "Are you sure you want to delete this key?",
                                      preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) { self.activityDidFinish(false) }
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive, handler: { (UIAlertAction) in
            
            Store.shared.remove(self.item.identifier)
            
            alert.dismiss(animated: true) { self.activityDidFinish(true) }
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
        return "Rename"
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
        
        let alert = UIAlertController(title: "Rename",
                                      message: "Type a user friendly name for this lock.",
                                      preferredStyle: .alert)
        
        alert.addTextField { $0.text = Store.shared[lock: self.item.identifier]!.name }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .`default`, handler: { (UIAlertAction) in
            
            Store.shared[lock: self.item.identifier]!.name = alert.textFields![0].text ?? ""
            
            alert.dismiss(animated: true) { self.activityDidFinish(true) }
            
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .destructive, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) { self.activityDidFinish(false) }
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
        return "Home Mode"
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
        
        let alert = UIAlertController(title: "Home Mode",
                                      message: "Enable Home Mode on this device?",
                                      preferredStyle: .alert)
        
        func enableHomeKit(_ enable: Bool = true) {
            
            guard let lockItem = self.item,
                let lockCache = Store.shared[lock: lockItem.identifier],
                let keyData = Store.shared[key: lockCache.key.identifier],
                let peripheral = Store.shared[peripheral: lockItem.identifier] // Lock must be reachable
                else { alert.dismiss(animated: true) { self.activityDidFinish(false) }; return }
            
            async {
                
                //do { try LockManager.shared.enableHomeKit(lockItem.identifier, key: (lockCache.keyIdentifier, keyData), enable: enable) }
                
                //catch { mainQueue { alert.showErrorAlert("\(error)"); self.activityDidFinish(false) }; return }
                
                mainQueue { alert.dismiss(animated: true) { self.activityDidFinish(true) } }
            }
        }
            
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { (UIAlertAction) in
                        
            alert.dismiss(animated: true) { self.activityDidFinish(false) }
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Yes"), style: .`default`, handler: { (UIAlertAction) in
            
            enableHomeKit()
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "No"), style: .`default`, handler: { (UIAlertAction) in
            
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
        return "Update"
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
        
        let lockItem = self.item!
        
        let alert = UIAlertController(title: "Update Lock",
                                      message: "Are you sure you want to update the lock's software?",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) { self.activityDidFinish(false) }
        }))
        
        alert.addAction(UIAlertAction(title: "Update", style: .`default`, handler: { (UIAlertAction) in
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

#if canImport(IntentsUI)
import IntentsUI

public final class AddVoiceShortcutActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.addVoiceShortcut.activityType
    }
    
    public  override var activityTitle: String? {
        return "Add to Siri"
    }
    
    public override var activityImage: UIImage? {
        return R.image.activitySiri()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        guard #available(iOS 12, *)
            else { return false }
        
        guard let lockItem = activityItems.first as? LockActivityItem,
            let _ = Store.shared[lock: lockItem.identifier]
            else { return false }
        
        return true
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        
        self.item = activityItems.first as? LockActivityItem
    }
    
    public override var activityViewController: UIViewController? {
        
        guard #available(iOS 12, *)
            else { return nil }
        
        guard let lockItem = self.item
            else { fatalError() }
        
        guard let lockCache = Store.shared[lock: lockItem.identifier]
            else { assertionFailure("Invalid lock"); return nil }
        
        let intent = UnlockIntent(lock: lockItem.identifier, name: lockCache.name)
        let shortcut = INShortcut.intent(intent)
        let viewController = INUIAddVoiceShortcutViewController(shortcut: shortcut)
        viewController.modalPresentationStyle = .formSheet
        viewController.delegate = self
        return viewController
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
