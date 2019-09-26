//
//  NewKeySelectPermissionViewController.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 4/26/16.
//  Copyright © 2016 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreLock
import Foundation
import JGProgressHUD
import SwiftUI

public final class NewKeySelectPermissionViewController: UITableViewController, NewKeyViewController {
    
    // MARK: - Properties
    
    public var completion: (((invitation: NewKey.Invitation, sender: PopoverPresentingView)?) -> ())?
    
    public var lockIdentifier: UUID!
    
    public var progressHUD: JGProgressHUD?
    
    private var permissionTypes: [PermissionType] = [.admin, .anytime]
    
    // MARK: - Loading
    
    public static func fromStoryboard(with lock: UUID, completion: (((invitation: NewKey.Invitation, sender: PopoverPresentingView)?) -> ())? = nil) -> NewKeySelectPermissionViewController {
        
        guard let viewController = R.storyboard.newKey.newKeySelectPermissionViewController()
            else { fatalError("Could not load \(self) from storyboard") }
        
        viewController.lockIdentifier = lock
        viewController.completion = completion
        return viewController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // set user activity
        userActivity = NSUserActivity(.action(.shareKey(lockIdentifier)))
        userActivity?.becomeCurrent()
        
        // setup table view
        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableView.automaticDimension
        
        if #available(iOSApplicationExtension 13, *) {
            permissionTypes.append(.scheduled)
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let progressHUD = self.progressHUD {
            view.bringSubviewToFront(progressHUD)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func cancel(_ sender: AnyObject?) {
        
        let completion = self.completion // for ARC
        
        self.dismiss(animated: true) { completion?(nil) }
    }
    
    // MARK: - Methods
    
    private func description(for permission: PermissionType) -> String {
        
        switch permission {
        case .admin:
            return R.string.newKeySelectPermissionViewController.adminDescription()
        case .anytime:
            return R.string.newKeySelectPermissionViewController.anytimeDescription()
        case .scheduled:
            return R.string.newKeySelectPermissionViewController.scheduledDescription()
        case .owner:
            assertionFailure("Cannot create owner keys")
            return "" // should never show
        }
    }
    
    private func configure(cell: PermissionTypeTableViewCell, at indexPath: IndexPath) {
        
        let permissionType = permissionTypes[indexPath.row]
        
        cell.permissionView.permission = permissionType
        cell.permissionTypeLabel.text = permissionType.localizedText
        cell.permissionDescriptionLabel.text = description(for: permissionType)
    }
    
    // MARK: - UITableViewDataSource
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        return permissionTypes.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.permissionTypeTableViewCell, for: indexPath)
            else { fatalError() }
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath) as! PermissionTypeTableViewCell
        
        let selectedType = permissionTypes[indexPath.row]
        
        switch selectedType {
        case .owner:
            fatalError("Cannot create owner keys")
        case .admin:
            // sender: .view(cell.permissionImageView)
            newKey(permission: .admin) { [weak self] in
                self?.completion?(($0, .view(cell.permissionView)))
            }
        case .anytime:
            newKey(permission: .anytime) { [weak self] in
                self?.completion?(($0, .view(cell.permissionView)))
            }
        case .scheduled:
            
            guard #available(iOSApplicationExtension 13, *) else {
                assertionFailure("Only available on iOS 13")
                return
            }
            
            let viewController = UIHostingController(rootView: PermissionScheduleView())
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

// MARK: - ProgressHUDViewController

extension NewKeySelectPermissionViewController: ProgressHUDViewController { }

// MARK: - View Controller Extensions

public extension UIViewController {
    
    func shareKey(lock identifier: UUID, completion: @escaping (((invitation: NewKey.Invitation, sender: PopoverPresentingView)?) -> ())) {
        
        let newKeyViewController = NewKeySelectPermissionViewController.fromStoryboard(with: identifier, completion: completion)
        let navigationController = UINavigationController(rootViewController: newKeyViewController)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func shareKey(lock identifier: UUID) {
        
        self.shareKey(lock: identifier) { [weak self] in
            guard let self = self else { return }
            guard let (invitation, sender) = $0 else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            // show share sheet
            (self.presentedViewController ?? self).share(invitation: invitation, sender: sender) {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}

// MARK: - Supporting Types

final class PermissionTypeTableViewCell: UITableViewCell {
    
    @IBOutlet private(set) weak var permissionView: PermissionIconView!
    @IBOutlet private(set) weak var permissionTypeLabel: UILabel!
    @IBOutlet private(set) weak var permissionDescriptionLabel: UILabel!
}
