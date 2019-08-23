//
//  LogViewController.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

final class LogViewController: UITableViewController {
    
    // MARK: - Properties
    
    private var log: Log = .shared {
        didSet { configureView() }
    }
    
    private var items = [String]()
    
    private lazy var nameDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    // MARK: - Loading
    
    public static func fromStoryboard(with log: Log = .shared) -> LogViewController {
        let viewController = R.storyboard.logs.logViewController()!
        viewController.log = log
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure table view
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        
        // load log
        configureView()
    }
    
    // MARK: - Actions
    
    @IBAction func share(_ sender: UIBarButtonItem) {
        
        let activityViewController = UIActivityViewController(activityItems: [log.url],
                                                              applicationActivities: nil)
        
        self.present(activityViewController, sender: .barButtonItem(sender))
    }
    
    // MARK: - Private Methods
    private subscript (indexPath: IndexPath) -> String {
        get { return items[indexPath.row] }
    }
    
    private func configureView() {
        
        let title: String
        if let metadata = log.metadata {
            title = metadata.bundle.symbol + " " + nameDateFormatter.string(from: metadata.created)
        } else {
            title = log.url.lastPathComponent.replacingOccurrences(of: "." + Log.fileExtension, with: "")
        }
        self.navigationItem.title = title
        
        let text = try! log.load()
        
        // parse into lines
        self.items = text.components(separatedBy: "\n").filter { $0.isEmpty == false }
        
        tableView.reloadData()
    }
    

    private func configure(cell: UITableViewCell, with item: String) {
        
        cell.textLabel?.text = item
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.logEntryTableViewCell, for: indexPath)!
        
        let item = self[indexPath]
        
        configure(cell: cell, with: item)
        
        return cell
    }
}
