//
//  LockPermissionsViewController.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 9/25/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import Bluetooth
import GATT
import CoreLock
import JGProgressHUD

final class LockPermissionsViewController: UITableViewController, ActivityIndicatorViewController {
    
    // MARK: - Properties
    
    var lockIdentifier: UUID!
    
    var completion: (() -> ())?
    
    private(set) var list = KeysList() {
        didSet { configureView() }
    }
    
    let progressHUD = JGProgressHUD(style: .dark)
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(lockIdentifier != nil, "No lock set")
        
        // set user activity
        userActivity = NSUserActivity(.action(.shareKey(lockIdentifier)))
        
        // setup table view
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.register(LockTableViewCell.nib, forCellReuseIdentifier: LockTableViewCell.reuseIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.bringSubviewToFront(progressHUD)
    }
    
    // MARK: - Actions
    
    @IBAction func reloadData(_ sender: AnyObject? = nil) {
        
        self.showProgressHUD()
        
        let lockIdentifier = self.lockIdentifier!
        
        guard let lockCache = Store.shared[lock: lockIdentifier],
            let keyData = Store.shared[key: lockCache.key.identifier]
            else { fatalError() }
        
        async { [weak self] in
            let key = KeyCredentials(identifier: lockCache.key.identifier, secret: keyData)
            do {
                guard let peripheral = Store.shared[peripheral: lockIdentifier]
                    else { throw CentralError.unknownPeripheral }
                try LockManager.shared.listKeys(for: peripheral, with: key, notification: { (list, isComplete) in
                    mainQueue { self?.list = list }
                })
                mainQueue { self?.dismissProgressHUD() }
            }
            catch {
                mainQueue {
                    self?.showErrorAlert("\(error)",
                        okHandler: { self?.tableView.reloadData() },
                        retryHandler: { self?.reloadData() })
                }
                return
            }
        }
    }
    
    @IBAction func newKey(_ sender: AnyObject? = nil) {
        
        let navigationController = UIStoryboard(name: "NewKey", bundle: nil).instantiateInitialViewController() as! UINavigationController
        let destinationViewController = navigationController.viewControllers.first! as! NewKeySelectPermissionViewController
        destinationViewController.lockIdentifier = lockIdentifier
        destinationViewController.completion = { _ in mainQueue { self.reloadData() } }
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @IBAction func done(_ sender: AnyObject? = nil) {
        
        self.dismiss(animated: true, completion: completion)
    }
    
    // MARK: - Private Methods
    
    private func configureView() {
        
        refreshControl?.endRefreshing()
        tableView.reloadData()
    }
    
    private func configure(cell: LockTableViewCell, at indexPath: IndexPath) {
        
        let item = self[indexPath]
        let permissionImage: UIImage
        let permissionText: String
        
        switch item.permission {
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
        
        cell.lockTitleLabel.text = item.name
        cell.lockImageView.image = permissionImage
        cell.lockDetailLabel.text = permissionText
        cell.activityIndicatorView.isHidden = true
        cell.lockImageView?.isHidden = false
    }
    
    // MARK: - Suscripting
    
    private subscript (section: Section) -> [Item] {
        
        switch section {
        case .keys: return list.keys.map { .key($0) }
        case .pending: return list.newKeys.map { .newKey($0) }
        }
    }
    
    private subscript (indexPath: IndexPath) -> Item {
        
        guard let section = Section(rawValue: indexPath.section)
            else { fatalError("Invalid section \(indexPath.section)") }
        
        let keys = self[section]
        let key = keys[indexPath.row]
        return key
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return Section.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        
        guard let section = Section(rawValue: sectionIndex)
            else { fatalError("Invalid section \(sectionIndex)") }
        
        return self[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: LockTableViewCell.reuseIdentifier, for: indexPath) as! LockTableViewCell
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let section = Section(rawValue: section)!
        
        switch section {
        case .keys: return nil
        case .pending: return self[section].isEmpty ? nil : "Pending Keys"
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // show key info
        
        //let key = self[indexPath]
        
        // present key detail VC
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        var actions = [UITableViewRowAction]()
        
        let lockIdentifier = self.lockIdentifier!
        
        guard let lockCache = Store.shared[lock: lockIdentifier],
            let keyData = Store.shared[key: lockCache.key.identifier]
            else { return nil }
        
        let key = KeyCredentials(identifier: lockCache.key.identifier, secret: keyData)
        
        let keyEntry = self[indexPath]
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") {
            
            assert($1 == indexPath)
            
            let alert = UIAlertController(title: NSLocalizedString("Confirmation", comment: "DeletionConfirmation"),
                                          message: "Are you sure you want to delete this key?",
                                          preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { (UIAlertAction) in
                
                alert.dismiss(animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive, handler: { (UIAlertAction) in
                
                alert.dismiss(animated: true) { }
                
                self.showProgressHUD()
                
                async { [weak self] in
                    
                    do {
                        guard let peripheral = Store.shared[peripheral: lockIdentifier]
                            else { return }
                        
                        try LockManager.shared.removeKey(keyEntry.identifier, type: keyEntry.type, for: peripheral, with: key)
                        
                    }
                    catch {
                        mainQueue {
                            self?.showErrorAlert(error.localizedDescription)
                            self?.dismissProgressHUD(animated: false)
                        }
                        return
                    }
                    mainQueue {
                        self?.list.remove(keyEntry.identifier, type: keyEntry.type)
                        self?.dismissProgressHUD(animated: true)
                    }
                }                
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        
        actions.append(delete)
        
        return actions
    }
}

// MARK: - Supporting Types

extension LockPermissionsViewController {
    
    enum Section: Int {
        
        static let count = 2
        
        case keys, pending
    }
    
    enum Item {
        
        case key(Key)
        case newKey(NewKey)
        
        var identifier: UUID {
            switch self {
            case let .key(value): return value.identifier
            case let .newKey(value): return value.identifier
            }
        }
        
        var name: String {
            switch self {
            case let .key(value): return value.name
            case let .newKey(value): return value.name
            }
        }
        
        var permission: Permission {
            switch self {
            case let .key(value): return value.permission
            case let .newKey(value): return value.permission
            }
        }
        
        var type: KeyType {
            switch self {
            case .key: return .key
            case .newKey: return .newKey
            }
        }
    }
}
