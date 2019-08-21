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

public final class LockViewController: UITableViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private(set) weak var unlockButton: UIButton!
    @IBOutlet private(set) weak var lockIdentifierLabel: UILabel!
    @IBOutlet private(set) weak var keyIdentifierLabel: UILabel!
    @IBOutlet private(set) weak var permissionLabel: UILabel!
    @IBOutlet private(set) weak var versionLabel: UILabel!
    
    // MARK: - Properties
    
    public var lockIdentifier: UUID! {
        didSet { if self.isViewLoaded { self.configureView() } }
    }
    
    private let progressHUD = JGProgressHUD(style: .dark)
    
    @available(iOS 10.0, *)
    private lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        return feedbackGenerator
    }()
    
    // MARK: - Loading
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        guard lockIdentifier != nil
            else { fatalError("Lock identifer not set") }
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableFooterView = UIView()
        
        configureView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 10.0, *) {
            feedbackGenerator.prepare()
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        userActivity = NSUserActivity(.view(.lock(lockIdentifier)))
        userActivity?.becomeCurrent()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.bringSubviewToFront(progressHUD)
    }
    
    // MARK: - Actions
    
    @IBAction func showActionMenu(_ sender: UIBarButtonItem) {
        
        let lockIdentifier = self.lockIdentifier!
        
        let foundLock = Store.shared[lock: lockIdentifier]
        
        let isScanning = Store.shared.scanning.value == false
        
        let shouldScan = foundLock == nil && isScanning == false
        
        func show() {
            
            let activities = [
                NewKeyActivity(),
                ManageKeysActivity(),
                HomeKitEnableActivity(),
                RenameActivity(),
                UpdateActivity(),
                DeleteLockActivity()
            ]
            
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
                do { try Store.shared.scan(duration: 3) }
                
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
    
    @IBAction func unlock(_ sender: UIButton) {
        
        unlock()
    }
    
    public func unlock() {
        
        guard let lockIdentifier = self.lockIdentifier
            else { assertionFailure(); return }
        
        loadViewIfNeeded()
        
        log("Unlock \(lockIdentifier)")
        
        guard let lockCache = Store.shared[lock: lockIdentifier]
            else { assertionFailure("No stored cache for lock"); return }
        
        guard let keyData = Store.shared[key: lockCache.key.identifier]
            else { assertionFailure("No stored key for lock"); return }
        
        self.userActivity?.resignCurrent()
        self.userActivity = NSUserActivity(.action(.unlock(lockIdentifier)))
        self.userActivity?.becomeCurrent()
        
        if #available(iOS 10.0, *) {
            feedbackGenerator.impactOccurred()
        }
        
        let key = KeyCredentials(identifier: lockCache.key.identifier, secret: keyData)
        
        unlockButton.isEnabled = false
        
        async { [weak self] in
            
            guard let controller = self else { return }
            
            // enable action button
            defer { mainQueue { controller.unlockButton.isEnabled = true } }
            
            do {
                guard let peripheral = try Store.shared.device(for: lockIdentifier, scanDuration: 1.0) else {
                    mainQueue { controller.showErrorAlert("Lock not nearby.") }
                    return
                }
                try Store.shared.unlock(peripheral)
            }
            
            catch { mainQueue { controller.showErrorAlert("\(error)") }; return }
            
            log("Successfully unlocked lock \"\(controller.lockIdentifier!)\"")
        }
    }
    
    // MARK: - Methods
    
    private func configureView() {
        
        // Lock has been deleted
        guard let lockCache = Store.shared[lock: lockIdentifier]
            else { assertionFailure("Invalid lock \(lockIdentifier!)"); return }
        
        // activity
        self.userActivity = NSUserActivity(.view(.lock(lockIdentifier)))
        
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

// MARK: - Extensions

extension UIViewController {
    
    @discardableResult
    func view(lock identifier: UUID) -> Bool {
        
        guard Store.shared[lock: identifier] != nil else {
            self.showErrorAlert("No key for lock \(identifier).")
            return false
        }
        
        let navigationController = UIStoryboard(name: "LockDetail", bundle: nil).instantiateInitialViewController() as! UINavigationController
        
        let lockViewController = navigationController.topViewController as! LockViewController
        lockViewController.lockIdentifier = identifier
        show(lockViewController, sender: self)
        
        return true
    }
}
