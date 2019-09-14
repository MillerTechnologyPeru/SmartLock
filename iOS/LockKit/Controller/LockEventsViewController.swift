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
    
    public lazy var activityIndicator: UIActivityIndicatorView = self.loadActivityIndicatorView()
    
    private var locks: Set<UUID> {
        return self.lock.flatMap { [$0] } ?? Set(Store.shared.locks.value.keys)
    }
    
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
    
    private var needsKeys = Set<UUID>()
    
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
        
        // load keys
        loadKeys()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
        reloadData()
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        
        if let refreshControl = refreshControl,
            refreshControl.isRefreshing {
            refreshControl.endRefreshing()
            showActivity()
        }
        
        super.viewDidDisappear(animated)
    }
    
    // MARK: - Actions
    
    @IBAction func refresh(_ sender: UIRefreshControl) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.reloadData()
        }
    }
    
    // MARK: - Methods
    
    private func configureView() {
        
        let context = Store.shared.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<EventManagedObject>()
        fetchRequest.entity = EventManagedObject.entity()
        fetchRequest.includesSubentities = true
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.includesPropertyValues = true
        fetchRequest.fetchBatchSize = 30
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(
                key: #keyPath(EventManagedObject.date),
                ascending: false
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
    
    private func reloadData() {
        
        // load keys if neccesary
        if needsKeys.isEmpty == false {
            loadKeys()
        }
        
        typealias FetchRequest = ListEventsCharacteristic.FetchRequest
        typealias Predicate = ListEventsCharacteristic.Predicate
        
        let locks = self.locks
        let context = Store.shared.backgroundContext
        performActivity({ [weak self] in
            for lock in locks {
                guard let device = try Store.shared.device(for: lock, scanDuration: 1.0) else {
                    if self?.lock == nil {
                        continue
                    } else {
                        throw CentralError.unknownPeripheral
                    }
                }
                let lastEventDate = try context.performErrorBlockAndWait {
                    try context.find(identifier: lock, type: LockManagedObject.self)
                        .flatMap { try $0.lastEvent(in: context)?.date }
                }
                let fetchRequest = FetchRequest(
                    offset: 0,
                    limit: nil,
                    predicate: Predicate(
                        keys: nil,
                        start: lastEventDate,
                        end: nil
                    )
                )
                do { try Store.shared.listEvents(device, fetchRequest: fetchRequest) }
                catch {
                    if self?.lock == nil {
                        continue
                    } else {
                        throw error
                    }
                }
            }
        }, completion: { (viewController, _) in
            viewController.needsKeys.removeAll()
            viewController.tableView.reloadData()
        })
    }
    
    private subscript (indexPath: IndexPath) -> EventManagedObject {
        return fetchedResultsController.object(at: indexPath) as! EventManagedObject
    }
    
    private func configure(cell: LockEventTableViewCell, at indexPath: IndexPath) {
        
        let managedObject = self[indexPath]
        guard let lock = managedObject.lock?.identifier else {
            assertionFailure("Missing identifier")
            return
        }
        let context = Store.shared.persistentContainer.viewContext
        let eventType = type(of: managedObject).eventType
        let action: String
        var keyName: String
        let key = try! managedObject.key(in: context)
        if key == nil {
            needsKeys.insert(lock)
        }
        switch managedObject {
        case is SetupEventManagedObject:
            action = "Setup"
            keyName = key?.name ?? ""
        case is UnlockEventManagedObject:
            action = "Unlocked"
            keyName = key?.name ?? ""
        case let event as CreateNewKeyEventManagedObject:
            if let newKey = try! event.confirmKeyEvent(in: context)?.key(in: context)?.name {
                action = "Shared \"\(newKey)\" key"
            } else if let newKey = try! event.newKey(in: context)?.name {
                action = "Shared \"\(newKey)\" key"
            } else {
                action = "Shared key"
                needsKeys.insert(lock)
            }
            keyName = key?.name ?? ""
        case let event as ConfirmNewKeyEventManagedObject:
            if let key = key,
                let permission = PermissionType(rawValue: numericCast(key.permission)) {
                action = "Created \"\(key.name ?? "")\" \(permission.localizedText) key"
                if let parentKey = try! event.createKeyEvent(in: context)?.key(in: context) {
                    keyName = "Shared by \"\(parentKey.name ?? "")\""
                } else {
                    keyName = ""
                    needsKeys.insert(lock)
                }
            } else {
                action = "Created key"
                keyName = ""
                needsKeys.insert(lock)
            }
        case let event as RemoveKeyEventManagedObject:
            if let removedKey = try! event.removedKey(in: context)?.name {
                action = "Removed \"\(removedKey)\" key"
            } else {
                action = "Removed key"
                needsKeys.insert(lock)
            }
            keyName = key?.name ?? ""
        default:
            fatalError("Invalid event \(managedObject)")
        }
        
        let lockName = managedObject.lock?.name ?? ""
        if self.lock == nil, lockName.isEmpty == false {
            keyName = keyName.isEmpty ? lockName : lockName + " - " + keyName
        }
        
        cell.actionLabel.text = action
        cell.keyNameLabel.text = keyName
        cell.symbolLabel.text = eventType.symbol
        cell.dateLabel.text = managedObject.date.flatMap { dateFormatter.string(from: $0) }
        cell.timeLabel.text = managedObject.date.flatMap { timeFormatter.string(from: $0) }
    }
    
    private func loadKeys() {
        
        let locks = self.locks.filter {
            Store.shared[lock: $0]?.key.permission.isAdministrator ?? false
                && (needsKeys.isEmpty ? true : needsKeys.contains($0))
        }
        performActivity({
            try locks.forEach {
                try Store.shared.device(for: $0, scanDuration: 1.0).flatMap {
                    let canListKeys = try Store.shared.listKeys($0)
                    assert(canListKeys)
                }
            }
        }, completion: { (viewController, _) in
            viewController.needsKeys.removeAll()
            viewController.tableView.reloadData()
        })
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

extension LockEventsViewController: TableViewActivityIndicatorViewController { }

// MARK: - Supporting Types

public final class LockEventTableViewCell: UITableViewCell {
    
    @IBOutlet private(set) weak var symbolLabel: UILabel!
    @IBOutlet private(set) weak var actionLabel: UILabel!
    @IBOutlet private(set) weak var keyNameLabel: UILabel!
    @IBOutlet private(set) weak var dateLabel: UILabel!
    @IBOutlet private(set) weak var timeLabel: UILabel!
}
