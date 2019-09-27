//
//  KeyViewController.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/27/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import Bluetooth
import GATT
import CoreLock
import JGProgressHUD
import SwiftUI

/// Key View Controller
public class KeyViewController: UITableViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private(set) weak var permissionView: PermissionIconView!
    
    // MARK: - Properties
    
    internal var data = [Section]() {
        didSet {
            loadViewIfNeeded()
            tableView.reloadData()
        }
    }
    
    @available(iOS 13.0, *)
    private lazy var timeFormatter = RelativeDateTimeFormatter()
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Loading
    
    public static func fromStoryboard(with key: Key) -> KeyViewController {
        
        guard let viewController = R.storyboard.key.keyViewController()
            else { fatalError("Could not load \(self) from storyboard") }
        viewController.title = R.string.keyViewController.navigationItemTitleKey()
        viewController.permissionView.permission = key.permission.type
        viewController.data = [
            Section(
                title: nil,
                items: viewController.map([
                    .name(key.name),
                    .permission(key.permission),
                    .created(key.created)
                ])
            )
        ]
        return viewController
    }
    
    public static func fromStoryboard(with newKey: NewKey) -> KeyViewController {
        
        guard let viewController = R.storyboard.key.keyViewController()
            else { fatalError("Could not load \(self) from storyboard") }
        viewController.title = R.string.keyViewController.navigationItemTitleNewKey()
        viewController.permissionView.permission = newKey.permission.type
        viewController.data = [
            Section(
                title: nil,
                items: viewController.map([
                    .name(newKey.name),
                    .permission(newKey.permission),
                    .created(newKey.created),
                    .expiration(newKey.expiration)
                ])
            )
        ]
        return viewController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
                
        self.tableView.tableFooterView = UIView()
    }
    
    // MARK: - Methods
    
    private subscript (indexPath: IndexPath) -> Item {
        return data[indexPath.section].items[indexPath.row]
    }
    
    internal func map(_ values: [KeyProperty]) -> [Item] {
                
        return values.map {
            switch $0 {
            case let .identifier(identifier):
                return .detail(R.string.keyViewController.identifierTitle(), identifier.uuidString)
            case let .name(name):
                return .detail(R.string.keyViewController.nameTitle(), name)
            case let .permission(permission):
                switch permission {
                case .owner:
                    fatalError("Invalid new key")
                case .admin,
                     .anytime:
                    return .detail(R.string.keyViewController.permissionTitle(), permission.type.localizedText)
                case let .scheduled(schedule):
                    if #available(iOS 13, *) {
                        return .detailDisclosure(R.string.keyViewController.permissionTitle(), permission.type.localizedText, {
                            let viewController = UIHostingController(rootView: PermissionScheduleView(schedule: schedule))
                            $0.show(viewController, sender: nil)
                        })
                    } else {
                        return .detail(R.string.keyViewController.permissionTitle(), permission.type.localizedText)
                    }
                }
            case let .lock(lock):
                return .detail(R.string.keyViewController.lockTitle(), lock.uuidString)
            case let .expiration(date):
                let expiration: String
                let timeRemaining = date.timeIntervalSinceNow
                if timeRemaining > 0 {
                    if #available(iOS 13.0, *) {
                        expiration = timeFormatter.localizedString(fromTimeInterval: timeRemaining)
                    } else {
                        expiration = dateFormatter.string(from: date)
                    }
                } else {
                    expiration = R.string.keyViewController.expirationExpired()
                }
                return .detail(R.string.keyViewController.expirationTitle(), expiration)
            case let .created(date):
                return .detail(R.string.keyViewController.createdTitle(), dateFormatter.string(from: date))
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.keyDetailTableViewCell, for: indexPath)
                else { fatalError("Unable to dequeue cell") }
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = detail
            return cell
        case let .detailDisclosure(title, detail, _):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.keyDetailDisclosureTableViewCell, for: indexPath)
                else { fatalError("Unable to dequeue cell") }
            cell.textLabel?.text = title
            cell.detailTextLabel?.text = detail
            return cell
        case let .button(title, _):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.keyBasicTableViewCell, for: indexPath)
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
        case let .detailDisclosure(_, _, action):
            action(self)
        default:
            break
        }
    }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return data[section].title
    }
}

// MARK: - Supporting Types

internal extension KeyViewController {
    
    struct Section {
        let title: String?
        let items: [Item]
    }
    
    enum Item {
        case detail(String, String)
        case detailDisclosure(String, String, (UIViewController) -> ())
        case button(String, (UIViewController) -> ())
    }
    
    enum KeyProperty {
        case identifier(UUID)
        case lock(UUID)
        case name(String)
        case permission(Permission)
        case expiration(Date)
        case created(Date)
    }
}
