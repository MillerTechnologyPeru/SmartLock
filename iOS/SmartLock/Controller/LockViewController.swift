//
//  LockViewController.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 6/30/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import Bluetooth
import GATT
import CoreLock

#if os(iOS)
import UIKit
import DarwinGATT
import JGProgressHUD
#endif

final class LockViewController: UITableViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private(set) weak var unlockButton: UIButton!
    @IBOutlet private(set) weak var lockIdentifierLabel: UILabel!
    @IBOutlet private(set) weak var keyIdentifierLabel: UILabel!
    @IBOutlet private(set) weak var permissionLabel: UILabel!
    @IBOutlet private(set) weak var versionLabel: UILabel!
    
    // MARK: - Properties
    
    var lockIdentifier: UUID! {
        
        didSet { if self.isViewLoaded { self.configureView() } }
    }
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard lockIdentifier != nil else { fatalError("Lock identifer not set") }
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableFooterView = UIView()
        
        configureView()
    }
    
    // MARK: - Actions
    /*
    @IBAction func showActionMenu(_ sender: UIBarButtonItem) {
        
        let lockIdentifier = self.lockIdentifier!
        
        let foundLock = Store.shared[lock: lockIdentifier]
        
        let isScanning = Store.shared.scanning.value == false
        
        let shouldScan = foundLock == nil && isScanning == false
        
        func show() {
            
            let activities = [NewKeyActivity(), ManageKeysActivity(), HomeKitEnableActivity(), RenameActivity(), UpdateActivity(), DeleteLockActivity()]
            
            let lockItem = LockActivityItem(identifier: lockIdentifier)
            
            let items = [lockItem, lockItem.text, lockItem.image] as [Any]
            
            let activityViewController = UIActivityViewController(activityItems: items, applicationActivities: activities)
            activityViewController.excludedActivityTypes = LockActivityItem.excludedActivityTypes
            activityViewController.modalPresentationStyle = .popover
            activityViewController.popoverPresentationController?.barButtonItem = sender
            
            self.present(activityViewController, animated: true, completion: nil)
        }
        
        if shouldScan {
            
            self.progressHUD.show(in: self.view)
            
            async { [weak self] in
                
                guard let controller = self else { return }
                
                // try to scan if not in range
                do { try LockManager.shared.scan() }
                    
                catch {
                    
                    mainQueue {
                        
                        controller.progressHUD.dismiss(animated: false)
                        controller.showErrorAlert("\(error)")
                    }
                }
                
                mainQueue {
                    
                    controller.progressHUD.dismiss()
                    show()
                }
            }
            
        } else {
            
            show()
        }
    }
    */
    @IBAction func unlock(_ sender: UIButton) {
        
        guard let lockIdentifier = self.lockIdentifier
            else { assertionFailure(); return }
        
        print("Unlocking \(lockIdentifier)")
        
        guard let lockCache = Store.shared[lock: lockIdentifier]
            else { assertionFailure("No stored cache for lock"); return }
        
        guard let keyData = Store.shared[key: lockCache.key.identifier]
            else { assertionFailure("No stored key for lock"); return }
        
        guard let (peripheral, characteristic) = Store.shared.lockInformation.value.first(where: { $0.value.identifier == lockIdentifier })
            else { showErrorAlert("Lock not in area. Please rescan for nearby locks."); return }
        
        let key = KeyCredentials(identifier: lockCache.key.identifier, secret: keyData)
        
        sender.isEnabled = false
        
        async { [weak self] in
            
            guard let controller = self else { return }
            
            // enable action button
            defer { mainQueue { sender.isEnabled = true } }
            
            do {
                try LockManager.shared.unlock(.default,
                                              for: peripheral,
                                              with: key,
                                              timeout: .gattDefaultTimeout)
            }
            
            catch { mainQueue { controller.showErrorAlert("\(error)") }; return }
            
            print("Successfully unlocked lock \"\(controller.lockIdentifier!)\"")
        }
    }
    
    // MARK: - Methods
    
    private func configureView() {
        
        // Lock has been deleted
        guard let lockCache = Store.shared[lock: lockIdentifier]
            else { assertionFailure("Invalid lock \(lockIdentifier!)"); return }
        
        // set lock name
        self.navigationItem.title = lockCache.name
        
        // setup unlock button
        switch lockCache.key.permission {
        case .owner, .admin, .anytime:
            self.unlockButton.isEnabled = true
        case let .scheduled(schedule):
            self.unlockButton.isEnabled = schedule.isValid()
        }
        
        self.lockIdentifierLabel.text = lockIdentifier!.uuidString
        self.keyIdentifierLabel.text = lockCache.key.identifier.uuidString
        self.versionLabel.text = lockCache.information.version.description
        
        let permissionImage: UIImage
        let permissionText: String
        
        switch lockCache.key.permission {
        case .owner:
            permissionImage = #imageLiteral(resourceName: "permissionBadgeOwner")
            permissionText = "Owner"
        case .admin:
            permissionImage = #imageLiteral(resourceName: "permissionBadgeAdmin")
            permissionText = "Admin"
        case .anytime:
            permissionImage = #imageLiteral(resourceName: "permissionBadgeAnytime")
            permissionText = "Anytime"
        case .scheduled:
            permissionImage = #imageLiteral(resourceName: "permissionBadgeScheduled")
            permissionText = "Scheduled" // FIXME: Localized Schedule text
        }
        
        self.permissionLabel.text = permissionText
    }
}
