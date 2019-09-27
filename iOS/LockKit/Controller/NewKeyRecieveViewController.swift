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
import SwiftUI

/// Receive New Key View Controller
public final class NewKeyRecieveViewController: KeyViewController {
    
    // MARK: - Properties
    
    public private(set) var invitation: NewKey.Invitation! {
        didSet { configureView() }
    }
    
    public var progressHUD: JGProgressHUD?
    
    public var completion: ((Bool) -> ())?
    
    private var canSave: Bool {
        return FileManager.Lock.shared.applicationData?.locks[invitation.lock] == nil
        && invitation.key.expiration.timeIntervalSinceNow > 0 // not expired
    }
    
    // MARK: - Loading
    
    public static func fromStoryboard(with invitation: NewKey.Invitation,
                                      completion: ((Bool) -> ())? = nil) -> NewKeyRecieveViewController {
        
        guard let viewController = R.storyboard.key.newKeyRecieveViewController()
            else { fatalError("Could not load \(self) from storyboard") }
        viewController.invitation = invitation
        viewController.completion = completion
        return viewController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(invitation != nil)
        
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
        
        guard let invitation = self.invitation else {
            assertionFailure()
            return
        }
        
        // set permission view
        let permission = invitation.key.permission
        self.permissionView.permission = permission.type
        
        // load table view
        var data = [
            Section(
                title: nil,
                items: map([
                    .name(invitation.key.name),
                    .permission(invitation.key.permission),
                    .created(invitation.key.created),
                    .expiration(invitation.key.expiration)
                ])
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
                        .button(R.string.keyViewController.saveTitle(), {
                            ($0 as? NewKeyRecieveViewController)?.save()
                        })
                    ]
                )
            )
        }
        
        self.data = data
    }
    
    private func save() {
        
        guard let newKeyInvitation = self.invitation else {
            assertionFailure()
            return
        }
        
        guard FileManager.Lock.shared.applicationData?.locks[newKeyInvitation.lock] == nil else {            self.showErrorAlert(R.string.error.existingKey())
            return
        }
        
        guard newKeyInvitation.key.expiration.timeIntervalSinceNow > 0 else {
            self.showErrorAlert(R.string.error.newKeyExpired())
            return
        }
        
        assert(canSave)
        
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
}

// MARK: - ActivityIndicatorViewController

extension NewKeyRecieveViewController: ProgressHUDViewController { }

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

