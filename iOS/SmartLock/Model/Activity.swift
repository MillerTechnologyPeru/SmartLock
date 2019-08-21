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

struct LockActivityItem {
    
    static let excludedActivityTypes: [UIActivity.ActivityType] = [.print,
                                                                   .assignToContact,
                                                                   .airDrop,
                                                                   .copyToPasteboard,
                                                                   .saveToCameraRoll,
                                                                   .postToFlickr]
    
    let identifier: UUID
    
    init(identifier: UUID) {
        
        self.identifier = identifier
    }
    
    // MARK: - Activity Values
    
    var text: String {
        
        guard let lockCache = Store.shared[lock: identifier]
            else { fatalError("Lock not in cache") }
        
        return "I unlocked my door \"\(lockCache.name)\" with Cerradura"
    }
    
    var image: UIImage {
        
        guard let lockCache = Store.shared[lock: identifier]
            else { fatalError("Lock not in cache") }
        
        switch lockCache.key.permission {
        case .owner: return #imageLiteral(resourceName: "permissionBadgeOwner")
        case .admin: return #imageLiteral(resourceName: "permissionBadgeAdmin")
        case .anytime: return #imageLiteral(resourceName: "permissionBadgeAnytime")
        case .scheduled: return #imageLiteral(resourceName: "permissionBadgeScheduled")
        }
    }
}

/// `UIActivity` types
enum LockActivity: String {
    
    case newKey = "com.colemancda.lock.activity.newKey"
    case manageKeys = "com.colemancda.lock.activity.manageKeys"
    case delete = "com.colemancda.lock.activity.delete"
    case rename = "com.colemancda.lock.activity.rename"
    case update = "com.colemancda.lock.activity.update"
    case homeKitEnable = "com.colemancda.lock.activity.homeKitEnable"
    
    var activityType: UIActivity.ActivityType {
        return UIActivity.ActivityType(rawValue: self.rawValue)
    }
}

/// Activity for sharing a key.
final class NewKeyActivity: UIActivity {
    
    override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    override var activityType: UIActivity.ActivityType? {
        
        return LockActivity.newKey.activityType
    }
    
    override var activityTitle: String? {
        
        return "Share Key"
    }
    
    override var activityImage: UIImage? {
        
        return #imageLiteral(resourceName: "activityNewKey")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
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
    
    override func prepare(withActivityItems activityItems: [Any]) {
        
        self.item = activityItems.first as? LockActivityItem
    }
    
    override var activityViewController: UIViewController? {
        
        let navigationController = UIStoryboard(name: "NewKey", bundle: nil).instantiateInitialViewController() as! UINavigationController
        
        let destinationViewController = navigationController.viewControllers.first! as! NewKeySelectPermissionViewController
        destinationViewController.lockIdentifier = item.identifier
        destinationViewController.completion = { self.activityDidFinish($0) }
        
        return navigationController
    }
}

/// Activity for managing keys of a lock.
final class ManageKeysActivity: UIActivity {
    
    override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    override var activityType: UIActivity.ActivityType? {
        
        return LockActivity.manageKeys.activityType
    }
    
    override var activityTitle: String? {
        
        return "Manage"
    }
    
    override var activityImage: UIImage? {
        
        return #imageLiteral(resourceName: "activityManageKeys")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
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
    
    override func prepare(withActivityItems activityItems: [Any]) {
        
        self.item = activityItems.first as? LockActivityItem
    }
    
    override var activityViewController: UIViewController? {
        
        let navigationController = UIStoryboard(name: "LockPermissions", bundle: nil).instantiateInitialViewController() as! UINavigationController
        
        let destinationViewController = navigationController.viewControllers.first! as! LockPermissionsViewController
        destinationViewController.lockIdentifier = item.identifier
        destinationViewController.completion = { self.activityDidFinish(true) }
        
        return navigationController
    }
}

/// Activity for deleting the lock locally.
final class DeleteLockActivity: UIActivity {
    
    override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    override var activityType: UIActivity.ActivityType? {
        
        return LockActivity.delete.activityType
    }
    
    override var activityTitle: String? {
        
        return "Delete"
    }
    
    override var activityImage: UIImage? {
        
        return #imageLiteral(resourceName: "activityDelete")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        return activityItems.first as? LockActivityItem != nil
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        
        self.item = activityItems.first as? LockActivityItem
    }
    
    override var activityViewController: UIViewController? {
        
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
final class RenameActivity: UIActivity {
    
    override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    override var activityType: UIActivity.ActivityType? {
        
        return LockActivity.rename.activityType
    }
    
    override var activityTitle: String? {
        
        return "Rename"
    }
    
    override var activityImage: UIImage? {
        
        return #imageLiteral(resourceName: "activityRename")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        return activityItems.first as? LockActivityItem != nil
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        
        self.item = activityItems.first as? LockActivityItem
    }
    
    override var activityViewController: UIViewController? {
        
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
final class HomeKitEnableActivity: UIActivity {
    
    override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    override var activityType: UIActivity.ActivityType? {
        
        return LockActivity.homeKitEnable.activityType
    }
    
    override var activityTitle: String? {
        
        return "Home Mode"
    }
    
    override var activityImage: UIImage? {
        
        return #imageLiteral(resourceName: "activityHomeKit")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
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
    
    override func prepare(withActivityItems activityItems: [Any]) {
        
        self.item = activityItems.first as? LockActivityItem
    }
    
    override var activityViewController: UIViewController? {
        
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

final class UpdateActivity: UIActivity {
    
    override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    override var activityType: UIActivity.ActivityType? {
        
        return LockActivity.homeKitEnable.activityType
    }
    
    override var activityTitle: String? {
        
        return "Update"
    }
    
    override var activityImage: UIImage? {
        
        return #imageLiteral(resourceName: "activityUpdate")
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        guard let lockItem = activityItems.first as? LockActivityItem,
            let lockCache = Store.shared[lock: lockItem.identifier],
            Store.shared[peripheral: lockItem.identifier] != nil // Lock must be reachable
            else { return false }
        
        guard lockCache.key.permission == .owner
            else { return false }
        
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        
        self.item = activityItems.first as? LockActivityItem
    }
    
    override var activityViewController: UIViewController? {
        
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
