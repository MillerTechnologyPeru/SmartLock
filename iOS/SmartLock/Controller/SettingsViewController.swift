//
//  SettingsViewController.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import CoreLock
import LockKit

final class SettingsViewController: UITableViewController {
    
    // MARK: - Properties
    
    private var data = [Section]()
    
    internal let version = "v\(AppVersion) (\(AppBuild))"
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure table view
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 35
        
        // update UI
        configureView()
    }
    
    // MARK: - Actions
    
    @IBAction func report(_ sender: UIView) {
        
        let activityViewController = UIActivityViewController(activityItems: [Log.shared.url],
                                                              applicationActivities: nil)
        
        self.present(activityViewController, sender: .view(sender))
    }
    
    // MARK: - Private Methods
    
    private subscript (indexPath: IndexPath) -> Item {
        return data[indexPath.section].items[indexPath.row]
    }
    
    private func configureView() {
        
        // update table view items
        data = [
            [
                Item(
                    icon: .report,
                    title: "Report",
                    accessory: .none,
                    action: { $0.show(LogsViewController.fromStoryboard(), sender: $1) /* $0.report($1.titleLabel) */ }
                ),
                Item(
                    icon: .logs,
                    title: "Logs",
                    accessory: .disclosureIndicator,
                    action: { $0.show(LogsViewController.fromStoryboard(), sender: $1) }
                )
            ]
        ]
        
        if #available(iOS 13, *) {
            let section: Section = [
                Item(
                    icon: .logs,
                    title: "Bluetooth",
                    accessory: .disclosureIndicator,
                    action: { $0.show(UIHostingController(rootView: BluetoothSettingsView()), sender: $1) }
                ),
                Item(
                    icon: .logs,
                    title: "iCloud",
                    accessory: .disclosureIndicator,
                    action: { $0.show(UIHostingController(rootView: CloudSettingsView()), sender: $1) }
                )
            ]
            data.append(section)
        }
        
        // set version footer for last section
        data[data.count - 1].footer = version
        
        tableView.reloadData()
    }
    
    private func configure(cell: SettingsTableViewCell, at indexPath: IndexPath) {
        
        let item = self[indexPath]
        
        cell.iconView.icon = item.icon
        cell.titleLabel.text = item.title
        cell.accessoryType = item.accessory
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.settingsTableViewCell, for: indexPath)!
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        
        let item = self[indexPath]
        
        guard let cell = tableView.cellForRow(at: indexPath) as? SettingsTableViewCell
            else { assertionFailure("Invalid cell"); return }
        
        item.action(self, cell)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection sectionIndex: Int) -> String? {
        
        let section = data[sectionIndex]
        return section.header
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection sectionIndex: Int) -> String? {
        
        let section = data[sectionIndex]
        return section.footer
    }
}

// MARK: - Supporting Types

private extension SettingsViewController {
    
    struct Section {
        
        var header: String?
        var footer: String?
        var items: [Item]
    }
    
    struct Item {
        
        typealias Icon = SettingsIconView.Icon
        
        let icon: Icon
        let title: String
        let accessory: UITableViewCell.AccessoryType
        let action: (SettingsViewController, SettingsTableViewCell) -> ()
    }
}

extension SettingsViewController.Section: ExpressibleByArrayLiteral {
    
    init(arrayLiteral elements: SettingsViewController.Item...) {
        self.init(header: nil, footer: nil, items: elements)
    }
}

final class SettingsTableViewCell: UITableViewCell {
    
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var iconView: SettingsIconView!
}
