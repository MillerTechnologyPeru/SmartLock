//
//  ContactsViewController.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CloudKit
import Contacts
import CoreLock

/// View controller for displaying all contacts using the application.
public final class ContactsViewController: TableViewController {
    
    // MARK: - Properties
    
    public lazy var activityIndicator: UIActivityIndicatorView = self.loadActivityIndicatorView()
    
    private lazy var nameFormatter = PersonNameComponentsFormatter()
    
    // MARK: - Loading
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup table view
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        
        // configure FRC
        configureView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        userActivity?.becomeCurrent()
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
        
        reloadData()
    }
    
    // MARK: - Methods
    
    private func configureView() {
        
        let context = Store.shared.managedObjectContext
        let fetchRequest = NSFetchRequest<ContactManagedObject>()
        fetchRequest.entity = ContactManagedObject.entity()
        fetchRequest.includesSubentities = false
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.includesPropertyValues = true
        fetchRequest.fetchBatchSize = 30
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(
                key: #keyPath(ContactManagedObject.identifier),
                ascending: false
            )
        ]
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil) as? NSFetchedResultsController<NSManagedObject>
    }
    
    private func reloadData() {
        
        // fetch contacts from CloudKit and insert into CoreData
        performActivity(queue: .app, {
            try Store.shared.updateContacts()
        })
    }
    
    private subscript (indexPath: IndexPath) -> ContactManagedObject {
        return fetchedResultsController.object(at: indexPath) as! ContactManagedObject
    }
    
    private func configure(cell: ContactTableViewCell, at indexPath: IndexPath) {
        
        let managedObject = self[indexPath]
        let name: String
        if let nameComponents = managedObject.nameComponents {
            name = nameFormatter.string(from: nameComponents)
        } else {
            name = "User"
        }
        cell.contactTitleLabel.text = name
        cell.contactDetailLabel.text = nil
        cell.contactImageView.image = nil
    }
}

// MARK: - ActivityIndicatorViewController

extension ContactsViewController: TableViewActivityIndicatorViewController { }

// MARK: - Supporting Types

final class ContactTableViewCell: UITableViewCell {
    
    @IBOutlet public private(set) weak var contactImageView: UIImageView!
    @IBOutlet public private(set) weak var contactTitleLabel: UILabel!
    @IBOutlet public private(set) weak var contactDetailLabel: UILabel!
    @IBOutlet public private(set) weak var activityIndicatorView: UIActivityIndicatorView!
}
