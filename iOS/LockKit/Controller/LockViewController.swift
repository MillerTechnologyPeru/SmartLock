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
import JGProgressHUD

public final class LockViewController: UITableViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private(set) weak var unlockButton: UIButton!
    @IBOutlet private(set) weak var lockIdentifierTitle: UILabel!
    @IBOutlet private(set) weak var keyIdentifierTitle: UILabel!
    @IBOutlet private(set) weak var permissionTitle: UILabel!
    @IBOutlet private(set) weak var versionTitle: UILabel!
    @IBOutlet private(set) weak var lockIdentifierLabel: UILabel!
    @IBOutlet private(set) weak var keyIdentifierLabel: UILabel!
    @IBOutlet private(set) weak var permissionLabel: UILabel!
    @IBOutlet private(set) weak var versionLabel: UILabel!
    
    // MARK: - Properties
    
    public var lockIdentifier: UUID! {
        didSet { if self.isViewLoaded { self.configureView() } }
    }
    
    public var progressHUD: JGProgressHUD?
    
    @available(iOS 10.0, *)
    private lazy var feedbackGenerator: UIImpactFeedbackGenerator = {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        return feedbackGenerator
    }()
    
    // MARK: - Loading
    
    public static func fromStoryboard(with lock: UUID) -> LockViewController {
        guard let viewController = R.storyboard.lockDetail.lockViewController()
            else { fatalError("Could not initialize \(self)") }
        viewController.lockIdentifier = lock
        return viewController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        guard lockIdentifier != nil
            else { fatalError("Lock identifer not set") }
        
        /// Setup table view
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.tableFooterView = UIView()
        
        // update UI
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
        
        if let progressHUD = self.progressHUD {
            view.bringSubviewToFront(progressHUD)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func showActionMenu(_ sender: UIBarButtonItem) {
        
        let lockIdentifier = self.lockIdentifier!
        
        let foundLock = Store.shared[lock: lockIdentifier]
        
        let isScanning = Store.shared.isScanning.value == false
        
        let shouldScan = foundLock == nil && isScanning == false
        
        func show() {
            
            let activities = [
                NewKeyActivity(),
                ManageKeysActivity(),
                HomeKitEnableActivity(),
                RenameActivity(),
                UpdateActivity(),
                DeleteLockActivity { [unowned self] in
                    self.navigationController?.popViewController(animated: true)
                },
                AddVoiceShortcutActivity()
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
            performActivity(queue: .bluetooth, {
                try Store.shared.scan(duration: 1.0)
            }, completion: { (viewController, _) in
                show()
            })
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
        
        donateUnlockIntent(for: lockIdentifier)
        
        if #available(iOS 10.0, *) {
            feedbackGenerator.impactOccurred()
        }
        
        let key = KeyCredentials(identifier: lockCache.key.identifier, secret: keyData)
        
        unlockButton.isEnabled = false
        
        DispatchQueue.bluetooth.async { [weak self] in
            
            guard let controller = self else { return }
            
            // enable action button
            defer { mainQueue { controller.unlockButton.isEnabled = true } }
            
            do {
                guard let peripheral = try Store.shared.device(for: lockIdentifier, scanDuration: 1.0) else {
                    mainQueue { controller.showErrorAlert(R.string.localizable.errorNotInRange()) }
                    return
                }
                try Store.shared.unlock(peripheral)
            }
            
            catch { mainQueue { controller.showErrorAlert("\(error.localizedDescription)") }; return }
            
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
        
        self.lockIdentifierTitle.text = R.string.lockViewController.lockIdentifierTitle()
        self.keyIdentifierTitle.text = R.string.lockViewController.keyIdentifierTitle()
        self.versionTitle.text = R.string.lockViewController.versionTitle()
        self.permissionTitle.text = R.string.lockViewController.permissionTitle()
        
        self.lockIdentifierLabel.text = lockIdentifier!.uuidString
        self.keyIdentifierLabel.text = lockCache.key.identifier.uuidString
        self.versionLabel.text = lockCache.information.version.description
        self.permissionLabel.text = lockCache.key.permission.localizedText
    }
}

// MARK: - ProgressHUDViewController

extension LockViewController: ProgressHUDViewController { }

// MARK: - Extensions

public extension UIViewController {
    
    @discardableResult
    func view(lock identifier: UUID) -> Bool {
        
        guard Store.shared[lock: identifier] != nil else {
            self.showErrorAlert(R.string.localizable.errorNoKey())
            return false
        }
        
        let viewController = LockViewController.fromStoryboard(with: identifier)
        show(viewController, sender: self)
        return true
    }
}
