//
//  LockEventsViewController.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/7/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CoreBluetooth
import Bluetooth
import GATT
import CoreLock
import JGProgressHUD

/// Lock Events View Controller
public final class LockEventsViewController: TableViewController {
    
    // MARK: - Properties
    
    public var lock: UUID? {
        didSet { configureView() }
    }
    
    public lazy var progressHUD: JGProgressHUD = .currentStyle(for: self)
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter
    }()
    
    private lazy var timeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    // MARK: - Loading
    
    /*
    public static func fromStoryboard(with lock: UUID? = nil) -> LockEventsViewController {
        
        guard let viewController = R.storyboard.events.lockEventsViewController()
            else { fatalError("Could not load \(self) from storyboard") }
        viewController.lock = lock
        return viewController
    }*/
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup table view
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        
        // configure FRC
        configureView()
        
        // load from BLE
        reloadData()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData(showProgressHUD: false)
    }
    
    // MARK: - Actions
    
    @IBAction func refresh(_ sender: UIRefreshControl) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.reloadData(showProgressHUD: false)
        }
    }
    
    // MARK: - Methods
    
    private func configureView() {
        
        let context = Store.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<EventManagedObject>()
        fetchRequest.entity = EventManagedObject.entity()
        fetchRequest.includesSubentities = true
        fetchRequest.fetchBatchSize = 30
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(
                key: #keyPath(EventManagedObject.date),
                ascending: true
            )
        ]
        if let lock = self.lock {
            fetchRequest.predicate = NSPredicate(
                format: "%K == %@",
                #keyPath(EventManagedObject.lock.identifier),
                lock as NSUUID
            )
        }
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil) as? NSFetchedResultsController<NSManagedObject>
        
    }
    
    private func reloadData(showProgressHUD: Bool = true) {
        
        refreshControl?.endRefreshing()
        
        let locks: Set<UUID> = self.lock.flatMap { [$0] } ?? Set(Store.shared.locks.value.keys)
        
        performActivity(showProgressHUD: showProgressHUD, { [weak self] in
            for lock in locks {
                guard let device = try Store.shared.device(for: lock, scanDuration: 1.0) else {
                    if self?.lock == nil {
                        continue
                    } else {
                        throw CentralError.unknownPeripheral
                    }
                }
                try Store.shared.listEvents(device, fetchRequest: nil)
            }
        }, completion: { (viewController, _) in
            viewController.refreshControl?.endRefreshing()
        })
    }
    
    private subscript (indexPath: IndexPath) -> EventManagedObject {
        return fetchedResultsController.object(at: indexPath) as! EventManagedObject
    }
    
    private func configure(cell: LockEventTableViewCell, at indexPath: IndexPath) {
        
        let managedObject = self[indexPath]
        let context = Store.shared.persistentContainer.viewContext
        let action: String
        var keyName: String
        switch managedObject {
        case let event as SetupEventManagedObject:
            action = "Setup"
            keyName = try! event.key(in: context)?.name ?? ""
        case let event as UnlockEventManagedObject:
            action = "Unlocked"
            keyName = try! event.key(in: context)?.name ?? ""
        case let event as CreateNewKeyEventManagedObject:
            action = "Shared key"
            keyName = try! event.key(in: context)?.name ?? ""
        case let event as ConfirmNewKeyEventManagedObject:
            if let key = try! event.key(in: context),
                let permission = PermissionType(rawValue: numericCast(key.permission)) {
                action = "Created \"\(key.name ?? "")\" \(permission.localizedText) key"
                if let parentKey = try! event.createKeyEvent(in: context)?.key(in: context) {
                    keyName = "Shared by \"\(parentKey.name ?? "")\""
                } else {
                    keyName = ""
                }
            } else {
                action = "Created key"
                keyName = ""
            }
        case let event as RemoveKeyEventManagedObject:
            if let removedKey = try! event.removedKey(in: context) {
                action = "Removed \"\(removedKey.name ?? "")\" key"
            } else {
                action = "Removed key"
            }
            keyName = try! event.key(in: context)?.name ?? ""
        default:
            fatalError("Invalid event \(managedObject)")
        }
        
        let lockName = managedObject.lock?.name ?? ""
        if self.lock != nil {
            keyName = keyName.isEmpty ? lockName : lockName + " - " + keyName
        }
        
        cell.actionLabel.text = action
        cell.keyNameLabel.text = keyName
        cell.dateLabel.text = managedObject.date.flatMap { dateFormatter.string(from: $0) }
        cell.timeLabel.text = managedObject.date.flatMap { timeFormatter.string(from: $0) }
    }
    
    // MARK: - UITableViewDataSource
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        //guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.lockEventTableViewCell, for: indexPath)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LockEventTableViewCell", for: indexPath) as? LockEventTableViewCell
            else { fatalError("Unable to dequeue cell") }
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    // MARK: - UITableViewDataSource
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
    }
}

// MARK: - ActivityIndicatorViewController

extension LockEventsViewController: ActivityIndicatorViewController { }

// MARK: - Supporting Types

public final class LockEventTableViewCell: UITableViewCell {
    
    @IBOutlet private(set) weak var actionLabel: UILabel!
    @IBOutlet private(set) weak var keyNameLabel: UILabel!
    @IBOutlet private(set) weak var dateLabel: UILabel!
    @IBOutlet private(set) weak var timeLabel: UILabel!
}
