//
//  KeysViewController.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 6/30/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import Bluetooth
import DarwinGATT
import GATT
import CoreLock
import LockKit
import JGProgressHUD
import OpenCombine

final class KeysViewController: UITableViewController {
    
    // MARK: - Properties
    
    private var items = [Item]() {
        didSet { configureView() }
    }
    
    private var locksObserver: AnyCancellable?
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup table view
        tableView.register(LockTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        // load data
        locksObserver = Store.shared.locks.sink { locks in
            mainQueue { [weak self] in self?.reloadData(locks) }
        }
        
        reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        userActivity = NSUserActivity(.screen(.keys))
        userActivity?.becomeCurrent()
        
        #if targetEnvironment(macCatalyst)
        syncCloud()
        #endif
    }
    
    // MARK: - Actions
    
    @IBAction func importFile(_ sender: UIBarButtonItem) {
        
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["com.colemancda.lock.ekey"], in: .import)
        documentPicker.delegate = self
        self.present(documentPicker, sender: .barButtonItem(sender))
    }
    
    // MARK: - Methods
    
    private subscript (indexPath: IndexPath) -> Item {
        return items[indexPath.row]
    }
    
    private func reloadData(_ locks: [UUID: LockCache] = Store.shared.locks.value) {
        
        self.items = locks
            .lazy
            .map { Item(identifier: $0.key, cache: $0.value) }
            .sorted(by: { $0.cache.key.created < $1.cache.key.created })
    }
    
    private func configureView() {
        
        self.tableView.reloadData()
    }
    
    private func stateChanged(_ state: DarwinBluetoothState) {
        
        mainQueue {
            self.tableView.setEditing(false, animated: true)
        }
    }
    
    private func configure(cell: LockTableViewCell, at indexPath: IndexPath) {
        
        let item = self[indexPath]
        let permission = item.cache.key.permission
        
        cell.lockTitleLabel.text = item.cache.name
        cell.lockDetailLabel.text = permission.localizedText
        cell.permissionView.permission = permission.type
        cell.activityIndicatorView.isHidden = true
        cell.permissionView.isHidden = false
    }
    
    private func select(_ item: Item) {
        select(lock: item.identifier)
    }
    
    @discardableResult
    internal func select(lock identifier: UUID, animated: Bool = true) -> LockViewController? {
        
        guard Store.shared[lock: identifier] != nil else {
            showErrorAlert("Invalid lock \(identifier)")
            return nil
        }
        
        let navigationController = UIStoryboard(name: "LockDetail", bundle: .lockKit).instantiateInitialViewController() as! UINavigationController
        
        let lockViewController = navigationController.topViewController as! LockViewController
        lockViewController.lockIdentifier = identifier
        if animated {
            self.show(lockViewController, sender: self)
        } else if let navigationController = self.navigationController {
            navigationController.pushViewController(lockViewController, animated: false)
        } else {
            assertionFailure()
        }
        return lockViewController
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(LockTableViewCell.self, for: indexPath)
            else { fatalError("Could not dequeue reusable cell \(LockTableViewCell.self)") }
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        let item = self[indexPath]
        select(item)
    }
    
    #if !targetEnvironment(macCatalyst)
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        if #available(iOS 13.0, *) {
            return nil
        }
        
        var actions = [UITableViewRowAction]()
        let item = self[indexPath]
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") {
            
            assert($1 == indexPath)
            let alert = UIAlertController(title: NSLocalizedString("Confirmation", comment: "DeletionConfirmation"),
                                          message: "Are you sure you want to delete this key?",
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: { (UIAlertAction) in
                alert.dismiss(animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .destructive, handler: { (UIAlertAction) in
                
                Store.shared.remove(item.identifier)
                
                alert.dismiss(animated: true, completion: nil)
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        
        actions.append(delete)
        return actions
    }
    #endif
    
    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        let item = self[indexPath]
        return UIContextMenuConfiguration(identifier: item.identifier as NSUUID, previewProvider: nil) { [weak self] (menuElements) -> UIMenu? in
            
            return self?.menu(forLock: item.identifier)
        }
    }
}

// MARK: - UIDocumentPickerDelegate

extension KeysViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        
        controller.dismiss(animated: true, completion: nil)
        
        // parse eKey file
        guard let url = urls.first,
            let data = try? Data(contentsOf: url),
            let newKey = try? JSONDecoder().decode(NewKey.Invitation.self, from: data) else {
                
                showErrorAlert("Invalid Key file.")
                return
        }
        
        self.open(newKey: newKey)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        
        controller.dismiss(animated: true, completion: nil)
        
        // parse eKey file
        guard let data = try? Data(contentsOf: url),
            let newKey = try? JSONDecoder().decode(NewKey.Invitation.self, from: data) else {
                
                showErrorAlert("Invalid Key file.")
                return
        }
        
        self.open(newKey: newKey)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Supporting Types

private extension KeysViewController {
    
    struct Item {
        let identifier: UUID
        let cache: LockCache
    }
}
