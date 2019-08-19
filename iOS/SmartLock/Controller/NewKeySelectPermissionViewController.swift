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

final class NewKeySelectPermissionViewController: UITableViewController, NewKeyViewController {
    
    // MARK: - Properties
    
    var completion: ((Bool) -> ())?
    
    var lockIdentifier: UUID!
    
    let progressHUD = JGProgressHUD(style: .dark)
    
    private let permissionTypes: [PermissionType] = [.admin, .anytime /*, .scheduled */ ]
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set user activity
        userActivity = NSUserActivity(.action(.shareKey(lockIdentifier)))
        
        // setup table view
        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        view.bringSubview(toFront: progressHUD)
    }
    
    // MARK: - Actions
    
    @IBAction func cancel(_ sender: AnyObject?) {
        
        let completion = self.completion // for ARC
        
        self.dismiss(animated: true) { completion?(false) }
    }
    
    // MARK: - Methods
    
    private func configure(cell: PermissionTypeTableViewCell, at indexPath: IndexPath) {
        
        let permissionType = permissionTypes[indexPath.row]
        
        let permissionImage: UIImage
        
        let permissionTypeName: String
        
        let permissionText: String
        
        switch permissionType {
            
        case .admin:
            
            permissionImage = UIImage(named: "permissionBadgeAdmin")!
            permissionTypeName = "Admin"
            permissionText = "Admin keys have unlimited access, and can create new keys."
            
        case .anytime:
            
            permissionImage = UIImage(named: "permissionBadgeAnytime")!
            permissionTypeName = "Anytime"
            permissionText = "Anytime keys have unlimited access, but cannot create new keys."
            
        case .scheduled:
            
            permissionImage = UIImage(named: "permissionBadgeScheduled")!
            permissionTypeName = "Scheduled"
            permissionText = "Scheduled keys have limited access during specified hours, and expire at a certain date. New keys cannot be created from this key"
            
        case .owner:
            
            fatalError("Cannot create owner keys")
        }
        
        cell.permissionImageView.image = permissionImage
        cell.permissionTypeLabel.text = permissionTypeName
        cell.permissionDescriptionLabel.text = permissionText
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        
        return permissionTypes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: PermissionTypeTableViewCell.resuseIdentifier, for: indexPath) as! PermissionTypeTableViewCell
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath) as! PermissionTypeTableViewCell
        
        let selectedType = permissionTypes[indexPath.row]
        
        switch selectedType {
        case .owner:
            fatalError("Cannot create owner keys")
        case .admin:
            newKey(permission: .admin, sender: .view(cell.permissionImageView)) { [unowned self] _ in
                self.completion?(true)
            }
        case .anytime:
            newKey(permission: .anytime, sender: .view(cell.permissionImageView)) { [unowned self] _ in
                self.completion?(true)
            }
        case .scheduled:
            fatalError("Not implemented")
        }
    }
}

// MARK: - Supporting Types

final class PermissionTypeTableViewCell: UITableViewCell {
    
    static let resuseIdentifier = "PermissionTypeTableViewCell"
    
    @IBOutlet weak var permissionImageView: UIImageView!
    
    @IBOutlet weak var permissionTypeLabel: UILabel!
    
    @IBOutlet weak var permissionDescriptionLabel: UILabel!
}
