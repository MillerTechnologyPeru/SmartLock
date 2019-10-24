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
import JGProgressHUD

/// View controller for displaying all contacts using the application.
public final class ContactsViewController: TableViewController {
    
    // MARK: - Properties
    
    public var didSelect: ((ContactsViewController, CloudUser.ID) -> ())?
    
    public var didCancel: ((ContactsViewController) -> ())?
    
    public var didShare: ((ContactsViewController, UIBarButtonItem) -> ())?
    
    public lazy var activityIndicator: UIActivityIndicatorView = self.loadActivityIndicatorView()
    
    private lazy var nameFormatter = PersonNameComponentsFormatter()
    
    private var applicationPermissionStatus: CKContainer_Application_PermissionStatus = .initialState
    
    // MARK: - Loading
    
    public static func fromStoryboard() -> ContactsViewController {
        
        guard let viewController = R.storyboard.contacts.contactsViewController()
            else { fatalError("Could not load \(self) from storyboard") }
        return viewController
    }
    
    public static func fromStoryboard(share invitation: NewKey.Invitation,
                                      completion: ((ContactsViewController, Bool) -> ())? = nil) -> ContactsViewController {
        
        let contactsViewController = ContactsViewController.fromStoryboard()
        contactsViewController.didSelect = { (viewController, contact) in
            let progressHUD = JGProgressHUD.currentStyle(for: viewController)
            progressHUD.show(in: viewController.navigationController?.view ?? viewController.view)
            DispatchQueue.app.async { [weak viewController] in
                do {
                    try Store.shared.cloud.share(invitation, to: contact)
                    mainQueue {
                        progressHUD.dismiss(animated: true)
                        completion?(contactsViewController, true)
                    }
                }
                catch {
                    mainQueue {
                        progressHUD.dismiss(animated: false)
                        viewController?.showErrorAlert(error.localizedDescription, okHandler: {
                            completion?(contactsViewController, false)
                        })
                    }
                }
            }
        }
        contactsViewController.didShare = {
            $0.shareActivity(invitation: invitation, cloudKit: false, sender: .barButtonItem($1)) {
                completion?(contactsViewController, $0)
            }
        }
        return contactsViewController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup table view
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        // configure FRC
        configureView()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        userActivity?.becomeCurrent()
        
        // configure bar button items
        if didCancel == nil {
            navigationItem.leftBarButtonItem = nil
        }
        if didShare == nil {
            navigationItem.rightBarButtonItem = nil
        }
        
        // CloudKit discoverability
        if applicationPermissionStatus != .granted {
            DispatchQueue.app.async {
                do {
                    guard try Store.shared.cloud.accountStatus() == .available else { return }
                    let status = try Store.shared.cloud.requestPermissions()
                    log("☁️ CloudKit permisions \(status == .granted ? "granted" : "not granted")")
                    mainQueue { [weak self] in
                        self?.applicationPermissionStatus = status
                        self?.reloadData()
                    }
                }
                catch { log("⚠️ Could not request CloudKit permissions. \(error.localizedDescription)") }
            }
        }
        
        if CNContactStore.authorizationStatus(for: .contacts) != .authorized {
            // request contacts permissions
            ContactManagedObject.contactStore.requestAccess(for: .contacts) { [weak self] (authorized, error) in
                if let error = error {
                    log("⚠️ Could not access address book. \(error.localizedDescription)")
                }
                mainQueue { self?.reloadData() }
            }
        }
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
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        
        self.didCancel?(self)
    }
    
    @IBAction func share(_ sender: UIBarButtonItem) {
        
        self.didShare?(self, sender)
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
            // make sure iCloud account is available.
            guard (try? Store.shared.cloud.accountStatus()) == .available else { return }
            // fetch contacts
            do { try Store.shared.updateContacts() }
            // ignore common errors
            catch CKError.networkUnavailable { }
            catch CKError.networkFailure { }
            catch CKError.requestRateLimited { }
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
        } else if #available(iOS 13, *) {
            image = UIImage(systemSymbol: .personCropCircleFill)
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
            // selection
            selection(self, .init(rawValue: identifier))
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
