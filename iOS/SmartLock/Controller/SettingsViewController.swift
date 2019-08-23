//
//  SettingsViewController.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import LockKit

final class SettingsViewController: UITableViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private(set) weak var versionLabel: UILabel!
    
    // MARK: - Properties
    
    private var data = [Section]()
    
    private let version = "v\(AppVersion) (\(AppBuild))"
    
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
        
        get { return data[indexPath.section].items[indexPath.row] }
    }
    
    private func configureView() {
        
        // set app version
        versionLabel.text = "v\(AppVersion) (\(AppBuild))"
        
        // update table view items
        data = [
            Section(header: nil,
                    footer: nil,
                    items: [
                        Item(icon: .report,
                             title: "Report",
                             action: { $0.show(LogsViewController.fromStoryboard(), sender: $1) /* $0.report($1.titleLabel) */ }),
                        Item(icon: .logs,
                             title: "Logs",
                             action: { $0.show(LogsViewController.fromStoryboard(), sender: $1) })
                ])
        ]
        
        tableView.reloadData()
    }
    
    private func configure(cell: SettingsTableViewCell, with item: Item) {
        
        cell.iconView.icon = item.icon
        cell.titleLabel.text = item.title
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return data[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.reuseIdentifier, for: indexPath) as! SettingsTableViewCell
        
        let item = self[indexPath]
        
        configure(cell: cell, with: item)
        
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
        
        let header: String?
        
        let footer: String?
        
        let items: [Item]
    }
    
    struct Item {
        
        typealias Icon = SettingsIconView.Icon
        
        let icon: Icon
        
        let title: String
        
        let action: (SettingsViewController, SettingsTableViewCell) -> ()
    }
}

final class SettingsTableViewCell: UITableViewCell {
    
    // MARK: - Class Properties
    
    public static let reuseIdentifier = "SettingsTableViewCell"
    
    // MARK: - IB Outlets
    
    @IBOutlet private(set) weak var titleLabel: UILabel!
    @IBOutlet private(set) weak var iconView: SettingsIconView!
}
