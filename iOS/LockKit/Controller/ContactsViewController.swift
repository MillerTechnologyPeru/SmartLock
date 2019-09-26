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
import ContactsUI
import CoreLock

/// View controller for displaying all contacts using the application.
public final class ContactsViewController: TableViewController {
    
    // MARK: - Properties
    
    public var didSelect: ((CloudUser.ID) -> ())?
    
    public lazy var activityIndicator: UIActivityIndicatorView = self.loadActivityIndicatorView()
    
    private lazy var nameFormatter = PersonNameComponentsFormatter()
    
    // MARK: - Loading
    
    public static func fromStoryboard(didSelect: ((CloudUser.ID) -> ())? = nil) -> ContactsViewController {
        
        guard let viewController = R.storyboard.contacts.contactsViewController()
            else { fatalError("Could not load \(self) from storyboard") }
        viewController.didSelect = didSelect
        return viewController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup table view
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        
        // configure FRC
        configureView()
        
        // CloudKit discoverability
        DispatchQueue.app.async {
            do {
                let status = try Store.shared.cloud.requestPermissions()
                log("☁️ CloudKit permisions \(status == .granted ? "granted" : "not granted")")
            }
            catch { log("⚠️ Could not request CloudKit permissions. \(error.localizedDescription)") }
        }
        
        // CloudKit address book access
        ContactManagedObject.contactStore.requestAccess(for: .contacts) { [weak self] (authorized, error) in
            if let error = error {
                log("⚠️ Could not access address book. \(error.localizedDescription)")
            }
            mainQueue { self?.reloadData() }
        }
        
        // fetch from server
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.reloadData()
        }
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
                key: #keyPath(ContactManagedObject.givenName),
                ascending: true
            ),
            NSSortDescriptor(
                key: #keyPath(ContactManagedObject.familyName),
                ascending: true
            ),
            NSSortDescriptor(
                key: #keyPath(ContactManagedObject.email),
                ascending: true
            ),
            NSSortDescriptor(
                key: #keyPath(ContactManagedObject.identifier),
                ascending: true
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
        
        let detail = managedObject.email ?? managedObject.phone
        
        let image: UIImage
        if let contactImage = managedObject.image.flatMap({ UIImage(data: $0) }) {
            image = contactImage
        } else if #available(iOS 13, *),
            let systemImage = UIImage(systemName: "person.crop.circle.fill") {
            image = systemImage
        } else {
            image = UIImage(permission: .admin)
        }
        cell.contactTitleLabel.text = name
        cell.contactDetailLabel.text = detail
        cell.contactImageView.image = image
    }
    
    // MARK: - UITableViewDataSource
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.contactTableViewCell, for: indexPath)
            else { fatalError("Unable to dequeue cell") }
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    // MARK: - UITableViewDataSource
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        
        let contact = self[indexPath]
        guard let identifier = contact.identifier else {
            assertionFailure("Invalid contact \(contact)")
            return
        }
        
        if let selection = self.didSelect {
            selection(.init(rawValue: identifier))
        } else {
            // select lock for key sharing
            
        }
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contactImageView.layer.cornerRadius = self.contactImageView.frame.size.width / 2
        self.contactImageView.clipsToBounds = true
    }
}
