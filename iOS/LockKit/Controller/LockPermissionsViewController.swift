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

public final class LockPermissionsViewController: UITableViewController {
    
    // MARK: - Properties
    
    public var lockIdentifier: UUID!
    
    public var completion: (() -> ())?
    
    private(set) var list = KeysList() {
        didSet { configureView() }
    }
    
    public var progressHUD: JGProgressHUD?
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    // MARK: - Loading
    
    public static func fromStoryboard(with lock: UUID, completion: (() -> ())? = nil) -> LockPermissionsViewController {
        
        guard let viewController = R.storyboard.lockPermissions.lockPermissionsViewController()
            else { fatalError("Unable to load \(self) from storyboard") }
        viewController.lockIdentifier = lock
        viewController.completion = completion
        return viewController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(lockIdentifier != nil, "No lock set")
        
        // set user activity
        userActivity = NSUserActivity(.action(.shareKey(lockIdentifier)))
        userActivity?.becomeCurrent()
        
        // setup table view
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.register(R.nib.lockTableViewCell)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.reloadData()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let progressHUD = self.progressHUD {
            view.bringSubviewToFront(progressHUD)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func reloadData(_ sender: AnyObject? = nil) {
        
        guard let lockIdentifier = self.lockIdentifier
            else { assertionFailure(); return }
        
        performActivity(queue: .bluetooth, {
            guard let peripheral = try Store.shared.device(for: lockIdentifier, scanDuration: 1.0)
                else { throw CentralError.unknownPeripheral }
            try Store.shared.listKeys(peripheral, notification: { (list, isComplete) in
                mainQueue { [weak self] in self?.list = list }
            })
        })
    }
    
    @IBAction func newKey(_ sender: AnyObject) {
        
        self.shareKey(lock: lockIdentifier)
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
        
        cell.lockTitleLabel.text = item.name
        cell.permissionView.permission = item.permission.type
        cell.lockDetailLabel.text = item.permission.localizedText
        cell.activityIndicatorView.isHidden = true
        cell.permissionView.isHidden = false
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
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        
        return Section.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        
        guard let section = Section(rawValue: sectionIndex)
            else { fatalError("Invalid section \(sectionIndex)") }
        
        return self[section].count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.lockTableViewCell, for: indexPath)!
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let section = Section(rawValue: section)!
        
        switch section {
        case .keys: return nil
        case .pending: return self[section].isEmpty ? nil : R.string.localizable.lockPermissionsPendingKeys()
        }
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // show key info
        
        //let key = self[indexPath]
        
        // present key detail VC
    }
    
    #if !targetEnvironment(macCatalyst)
    public override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        var actions = [UITableViewRowAction]()
        
        let lockIdentifier = self.lockIdentifier!
        
        guard let lockCache = Store.shared[lock: lockIdentifier],
            let keyData = Store.shared[key: lockCache.key.identifier]
            else { return nil }
        
        let key = KeyCredentials(identifier: lockCache.key.identifier, secret: keyData)
        
        let keyEntry = self[indexPath]
        
        let delete = UITableViewRowAction(style: .destructive, title: R.string.localizable.lockPermissionsDelete()) {
            
            assert($1 == indexPath)
            
            let alert = UIAlertController(title: R.string.localizable.lockPermissionsAlertTitle(),
                                          message: R.string.localizable.lockPermissionsAlertMessage(),
                                          preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: R.string.localizable.lockPermissionsAlertCancel(), style: .cancel, handler: { (UIAlertAction) in
                
                alert.dismiss(animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: R.string.localizable.lockPermissionsAlertDelete(), style: .destructive, handler: { (UIAlertAction) in
                
                alert.dismiss(animated: true) { }
                
                self.showActivity()
                
                DispatchQueue.bluetooth.async { [weak self] in
                    
                    do {
                        guard let peripheral = Store.shared[peripheral: lockIdentifier]
                            else { return }
                        
                        try LockManager.shared.removeKey(keyEntry.identifier, type: keyEntry.type, for: peripheral, with: key)
                        
                    }
                    catch {
                        mainQueue {
                            self?.showErrorAlert(error.localizedDescription)
                            self?.hideActivity(animated: false)
                        }
                        return
                    }
                    mainQueue {
                        self?.list.remove(keyEntry.identifier, type: keyEntry.type)
                        self?.hideActivity(animated: true)
                    }
                }                
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        
        actions.append(delete)
        
        return actions
    }
    #endif
}

// MARK: - ActivityIndicatorViewController

extension LockPermissionsViewController: ProgressHUDViewController { }

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
