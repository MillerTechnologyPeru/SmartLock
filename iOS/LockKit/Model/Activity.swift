//
//  Activity.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 7/3/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import LinkPresentation
import CoreLock
import JGProgressHUD

// MARK: - Lock Item

public final class LockActivityItem: NSObject {
    
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
    
    public let id: UUID
    
    public init(id: UUID) {
        self.id = id
    }
    
    // MARK: - Activity Values
    
    public var lock: LockCache? {
        return Store.shared[lock: identifier]
    }
    
    public var text: String {
        
        guard let lockCache = self.lock else {
            assertionFailure("Lock not in cache")
            return ""
        }
        
        return R.string.activity.lockActivityItemText(lockCache.name)
    }
    
    public var image: UIImage {
        
        guard let lockCache = self.lock else {
            assertionFailure("Lock not in cache")
            return UIImage(permission: .admin)
        }
        
        return UIImage(permission: lockCache.key.permission)
    }
}

// MARK: - New Key Activity

public final class NewKeyFileActivityItem: UIActivityItemProvider {
    
    public init(invitation: NewKey.Invitation) {
        self.invitation = invitation
        
        let url = type(of: self).url(for: invitation)
        do { try FileManager.default.removeItem(at: url) }
        catch { } // ignore
        super.init(placeholderItem: url)
    }
    
    private static func url(for invitation: NewKey.Invitation) -> URL {
        let fileName = invitation.key.name + "." + NewKey.Invitation.fileExtension
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        return fileURL
    }
    
    public let invitation: NewKey.Invitation
    
    public lazy var fileURL = type(of: self).url(for: invitation)
    
    private lazy var encoder = JSONEncoder()
    
    /// Generate the actual item.
    public override var item: Any {
        // save invitation file
        let url = type(of: self).url(for: invitation)
        do {
            let data = try encoder.encode(invitation)
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            assertionFailure("Could not create key file: \(error)")
            return url
        }
    }
    
    // MARK: - UIActivityItemSource
    
    public override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        
        return invitation.key.name
    }
    
    public override func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        
        return UIImage(permissionType: invitation.key.permission.type)
    }
    
    @available(iOSApplicationExtension 13.0, *)
    public override func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        
        let permissionImageURL = AssetExtractor.shared.url(for: invitation.key.permission.type.image)
        assert(permissionImageURL != nil, "Missing permission image")
        let metadata = LPLinkMetadata()
        metadata.title = invitation.key.name
        metadata.imageProvider = permissionImageURL.flatMap { NSItemProvider(contentsOf: $0) }
        return metadata
    }
}

public extension NewKeyFileActivityItem {
    
    static let excludedActivityTypes: [UIActivity.ActivityType] = [.postToTwitter,
                                                                   .postToFacebook,
                                                                   .postToWeibo,
                                                                   .postToTencentWeibo,
                                                                   .postToFlickr,
                                                                   .postToVimeo,
                                                                   .print,
                                                                   .assignToContact,
                                                                   .saveToCameraRoll,
                                                                   .addToReadingList,
                                                                   .openInIBooks,
                                                                   .markupAsPDF]
}

// MARK: - Activity Type

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

// MARK: - Activity

/// Activity for sharing a key.
public final class NewKeyActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.newKey.activityType
    }
    
    public override var activityTitle: String? {
        return R.string.activity.newKeyActivityTitle()
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityNewKey()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        guard let lockItem = activityItems.compactMap({ $0 as? LockActivityItem }).first,
            let lockCache = Store.shared[lock: lockItem.identifier]
            else { return false }
        
        // only owner and admin can share keys
        return lockCache.key.permission.isAdministrator
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        self.item = activityItems.compactMap({ $0 as? LockActivityItem }).first
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
        return R.string.activity.manageKeysActivityTitle()
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityManageKeys()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        guard let lockItem = activityItems.compactMap({ $0 as? LockActivityItem }).first,
            let lockCache = Store.shared[lock: lockItem.identifier]
            else { return false }
        
        return lockCache.key.permission.isAdministrator
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        self.item = activityItems.compactMap({ $0 as? LockActivityItem }).first
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
        return R.string.activity.deleteLockActivityTitle()
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityDelete()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return activityItems.compactMap({ $0 as? LockActivityItem }).first != nil
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        self.item = activityItems.compactMap({ $0 as? LockActivityItem }).first
    }
    
    public override var activityViewController: UIViewController? {
        
        return type(of: self).viewController(for: item.identifier, completion: { [weak self] (didDelete) in
            self?.activityDidFinish(didDelete)
            if didDelete { self?.completion?() }
        })
    }
    
    public static func viewController(for lock: UUID, completion: @escaping (Bool) -> ()) -> UIAlertController {
        
        let alert = UIAlertController(
            title: R.string.activity.deleteLockActivityAlertTitle(),
            message: R.string.activity.deleteLockActivityAlertMessage(),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: R.string.activity.deleteLockActivityAlertCancel(), style: .cancel, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) { completion(false) }
        }))
        
        alert.addAction(UIAlertAction(title: R.string.activity.deleteLockActivityAlertDelete(), style: .destructive, handler: { (UIAlertAction) in
            
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
        return R.string.activity.renameActivityTitle()
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityRename()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return activityItems.compactMap({ $0 as? LockActivityItem }).first != nil
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        self.item = activityItems.compactMap({ $0 as? LockActivityItem }).first
    }
    
    public override var activityViewController: UIViewController? {
        return type(of: self).viewController(for: item.identifier, completion: { [weak self] in
            self?.activityDidFinish($0)
        })
    }
    
    public static func viewController(for lock: UUID,
                                      completion: @escaping (Bool) -> ()) -> UIAlertController {
        
        let alert = UIAlertController(title: R.string.activity.renameActivityAlertTitle(),
                                      message: R.string.activity.renameActivityAlertMessage(),
                                      preferredStyle: .alert)
        
        alert.addTextField { $0.text = Store.shared[lock: lock]?.name }
        
        alert.addAction(UIAlertAction(title: R.string.activity.renameActivityAlertOK(), style: .`default`, handler: { (UIAlertAction) in
            
            Store.shared[lock: lock]?.name = alert.textFields?[0].text ?? ""
            alert.dismiss(animated: true) { completion(true) }
        }))
        
        alert.addAction(UIAlertAction(title: R.string.activity.renameActivityAlertCancel(), style: .destructive, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) { completion(false) }
        }))
        
        return alert
    }
}

public final class UpdateActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem!
    
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.update.activityType
    }
    
   public  override var activityTitle: String? {
        return R.string.activity.updateActivityTitle()
    }
    
    public override var activityImage: UIImage? {
        return R.image.activityUpdate()
    }
    
    public override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        
        guard let lockItem = activityItems.compactMap({ $0 as? LockActivityItem }).first,
            let lockCache = Store.shared[lock: lockItem.identifier]
            else { return false }
        
        guard lockCache.key.permission.isAdministrator
            else { return false }
        
        return true
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        
        self.item = activityItems.compactMap({ $0 as? LockActivityItem }).first
    }
    
    public override var activityViewController: UIViewController? {
        
        let lockItem = self.item!
        
        let alert = UIAlertController(title: R.string.activity.updateActivityAlertTitle(),
                                      message: R.string.activity.updateActivityAlertMessage(),
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: R.string.activity.updateActivityAlertCancel(), style: .cancel, handler: { (UIAlertAction) in
            
            alert.dismiss(animated: true) { self.activityDidFinish(false) }
        }))
        
        alert.addAction(UIAlertAction(title: R.string.activity.updateActivityAlertUpdate(), style: .`default`, handler: { (UIAlertAction) in
            
            let progressHUD = JGProgressHUD(style: .dark)
            
            func showProgressHUD() {
                
                progressHUD.show(in: alert.view)
                
                alert.view.isUserInteractionEnabled = false
            }
            
            func dismissProgressHUD(_ animated: Bool = true) {
                
                progressHUD.dismiss()
                
                alert.view.isUserInteractionEnabled = true
            }
            
            // fetch cache
            guard let lockCache = Store.shared[lock: lockItem.identifier],
                let keyData = Store.shared[key: lockCache.key.identifier]
                else { alert.dismiss(animated: true) { self.activityDidFinish(false) }; return }
            
            let key = KeyCredentials(identifier: lockCache.key.identifier, secret: keyData)
            
            showProgressHUD()
            
            DispatchQueue.app.async {
                
                let client = Store.shared.netServiceClient
                
                do {
                    guard let netService = try client.discover(duration: 1.0, timeout: 10.0).first(where: { $0.identifier == lockItem.identifier })
                        else { throw LockError.notInRange(lock: lockItem.identifier) }
                    
                    try client.update(for: netService, with: key, timeout: 30.0)
                }
                    
                catch {
                    mainQueue {
                        dismissProgressHUD(false)
                        alert.showErrorAlert("\(error)")
                        self.activityDidFinish(false)
                    }
                    return
                }
                
                mainQueue {
                    dismissProgressHUD()
                    self.activityDidFinish(true)
                    alert.dismiss(animated: true) { }
                }
            }
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
         return R.string.activity.shareKeyCloudKitActivityTitle()
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

public final class AddSiriShortcutActivity: UIActivity {
    
    public override class var activityCategory: UIActivity.Category { return .action }
    
    private var item: LockActivityItem?
    
    public override var activityType: UIActivity.ActivityType? {
        return LockActivity.addVoiceShortcut.activityType
    }
    
    public  override var activityTitle: String? {
        return R.string.activity.addVoiceShortcutActivityTitle()
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
        
        guard let lockItem = activityItems.compactMap({ $0 as? LockActivityItem }).first,
            let _ = Store.shared[lock: lockItem.identifier]
            else { return false }
        
        return true
        #endif
    }
    
    public override func prepare(withActivityItems activityItems: [Any]) {
        self.item = activityItems.compactMap({ $0 as? LockActivityItem }).first
    }
    
    public override var activityViewController: UIViewController? {
        
        #if targetEnvironment(macCatalyst)
        return nil
        #else
        guard #available(iOS 12, *)
            else { return nil }
        
        guard let lockItem = self.item
            else { assertionFailure(); return nil }
        
        guard let lockCache = Store.shared[lock: lockItem.identifier]
            else { assertionFailure("Invalid lock"); return nil }
        
        return INUIAddVoiceShortcutViewController(
            unlock: lockItem.identifier,
            cache: lockCache,
            delegate: self
        )
        #endif
    }
}

// MARK: - INUIAddVoiceShortcutViewControllerDelegate

@available(iOS 12, *)
extension AddSiriShortcutActivity: INUIAddVoiceShortcutViewControllerDelegate {
    
    public func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    public func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

#endif
