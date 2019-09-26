//
//  NewKeyRecieveViewController.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 7/11/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import Bluetooth
import GATT
import CoreLock
import JGProgressHUD

/// Receive New Key View Controller
public final class NewKeyRecieveViewController: UITableViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private(set) weak var permissionView: PermissionIconView!
    
    // MARK: - Properties
    
    public private(set) var newKey: NewKey.Invitation! {
        didSet { configureView() }
    }
        
    public var progressHUD: JGProgressHUD?
    
    public var completion: ((Bool) -> ())?
    
    private var data = [Section]() {
        didSet { tableView.reloadData() }
    }
    
    private var canSave: Bool {
        return FileManager.Lock.shared.applicationData?.locks[newKey.lock] == nil
        && newKey.key.expiration.timeIntervalSinceNow > 0 // not expired
    }
    
    @available(iOS 13.0, *)
    private lazy var timeFormatter = RelativeDateTimeFormatter()
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Loading
    
    public static func fromStoryboard(with newKey: NewKey.Invitation,
                                      completion: ((Bool) -> ())? = nil) -> NewKeyRecieveViewController {
        
        guard let viewController = R.storyboard.newKeyInvitation.newKeyRecieveViewController()
            else { fatalError("Could not load \(self) from storyboard") }
        viewController.newKey = newKey
        viewController.completion = completion
        return viewController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(newKey != nil)
        
        self.tableView.tableFooterView = UIView()
        
        // TODO: Observe Bluetooth State
        if LockManager.shared.central.state != .poweredOn, canSave {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.configureView()
            }
        }
        
        configureView()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let progressHUD = self.progressHUD {
            view.bringSubviewToFront(progressHUD)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func cancel(_ sender: UIBarItem) {
        if let completion = self.completion {
            completion(false)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        save()
    }
    
    // MARK: - Methods
    
    private subscript (indexPath: IndexPath) -> Item {
        return data[indexPath.section].items[indexPath.row]
    }
    
    private func configureView() {
        
        guard isViewLoaded else { return }
        
        guard let newKey = self.newKey else {
            assertionFailure()
            return
        }
        
        let permission = newKey.key.permission
        self.permissionView.permission = permission.type
        
        let keyName = newKey.key.name
        let lock = newKey.lock.uuidString
        let permissionDescription = permission.type.localizedText
        
        let expiration: String
        let timeRemaining = newKey.key.expiration.timeIntervalSinceNow
        if timeRemaining > 0 {
            if #available(iOS 13.0, *) {
                expiration = timeFormatter.localizedString(fromTimeInterval: timeRemaining)
            } else {
                expiration = dateFormatter.string(from: newKey.key.expiration)
            }
        } else {
            expiration = R.string.localizable.newKeyRecieveExpirationExpired()
        }
        
        var data = [
            Section(
                title: nil,
                items: [
                    .detail(R.string.localizable.newKeyRecieveNameTitle(), keyName),
                    .detail(R.string.localizable.newKeyRecievePermissionTitle(), permissionDescription),
                    .detail(R.string.localizable.newKeyRecieveExpirationTitle(), expiration),
                    .detail(R.string.localizable.newKeyRecieveLockTitle(), lock)
                ]
            )
        ]
        
        // add save button if not contained in navigation controller
        if canSave,
            LockManager.shared.central.state == .poweredOn,
            parent is UINavigationController == false {
            data.append(
                Section(
                    title: nil,
                    items: [
                        .button(R.string.localizable.newKeyRecieveSaveTitle(), { $0.save() })
                    ]
                )
            )
        }
        
        self.data = data
    }
    
    private func save() {
        
        guard let newKeyInvitation = self.newKey else {
            assertionFailure()
            return
        }
        
        guard FileManager.Lock.shared.applicationData?.locks[newKeyInvitation.lock] == nil else {
            self.showErrorAlert(R.string.localizable.newKeyRecieveError(newKey.lock.rawValue))
            return
        }
        
        let keyData = KeyData()
        showActivity()
        
        DispatchQueue.bluetooth.async { [weak self] in
            
            guard let controller = self else { return }
            
            do {
                
                // scan for lock if neccesary
                guard let device = try Store.shared.device(for: newKeyInvitation.lock, scanDuration: 2.0),
                    let information = Store.shared.lockInformation.value[device.scanData.peripheral]
                    else { throw CentralError.unknownPeripheral }
                
                // recieve new key
                let credentials = KeyCredentials(
                    identifier: newKeyInvitation.key.identifier,
                    secret: newKeyInvitation.secret
                )
                
                try LockManager.shared.confirmKey(.init(secret: keyData),
                                                  for: device.scanData.peripheral,
                                                  with: credentials)
                
                // update UI
                mainQueue {
                    
                    // save to cache
                    let lockCache = LockCache(
                        key: Key(
                            identifier: newKeyInvitation.key.identifier,
                            name: newKeyInvitation.key.name,
                            created: newKeyInvitation.key.created,
                            permission: newKeyInvitation.key.permission
                        ),
                        name: R.string.localizable.newLockName(),
                        information: .init(characteristic: information)
                    )
                    
                    Store.shared[lock: newKeyInvitation.lock] = lockCache
                    Store.shared[key: newKeyInvitation.key.identifier] = keyData
                    controller.hideActivity(animated: true)
                    controller.configureView()
                    controller.completion?(true)
                }
            }
            
            catch {
                
                mainQueue {
                    controller.hideActivity(animated: false)
                    controller.showErrorAlert(error.localizedDescription, okHandler: {
                        controller.completion?(false)
                    })
                }
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        
        return data.count
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return data[section].items.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = self[indexPath]
        
        switch item {
        case let .detail(title, detail):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.newKeyDetailTableViewCell, for: indexPath)
                else { fatalError("Unable to dequeue cell") }
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = detail
            return cell
        case let .button(title, _):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.newKeyBasicTableViewCell, for: indexPath)
            else { fatalError("Unable to dequeue cell") }
            cell.textLabel?.text = title
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        
        let item = self[indexPath]
        
        switch item {
        case let .button(_, action):
            action(self)
        default:
            break
        }
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return data[section].title
    }
}

// MARK: - ProgressHUDViewController

extension NewKeyRecieveViewController: ProgressHUDViewController { }

// MARK: - Supporting Types

private extension NewKeyRecieveViewController {
    
    struct Section {
        let title: String?
        let items: [Item]
    }
    
    enum Item {
        case detail(String, String)
        case button(String, (NewKeyRecieveViewController) -> ())
    }
}

// MARK: - View Controller Extensions

public extension UIViewController {
    
    func open(newKey: NewKey.Invitation, completion: ((Bool) -> ())? = nil) {
        
        let newKeyViewController = NewKeyRecieveViewController.fromStoryboard(with: newKey)
        newKeyViewController.completion = completion ?? { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        let navigationController = UINavigationController(rootViewController: newKeyViewController)
        present(navigationController, animated: true, completion: nil)
    }
}

