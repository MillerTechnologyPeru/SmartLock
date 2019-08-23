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
    
    var log: Log! {
        
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
        guard let log = self.log
            else { assertionFailure(); return }
        
        self.navigationItem.title = name(for: log)
        
        let text = try! log.load()
        
        // parse into lines
        self.items = text.components(separatedBy: "\n").filter { $0.isEmpty == false }
        
        tableView.reloadData()
    }
    

    private func configure(cell: UITableViewCell, with item: String) {
        
        cell.textLabel?.text = item
    }
    
    private func name(for log: Log) -> String {
        
        var name = log.url.lastPathComponent.replacingOccurrences(of: "." + Log.fileExtension, with: "")
        
        if let timeInterval = Int(name) {
            
            let date = Date(timeIntervalSince1970: TimeInterval(timeInterval))
            
            name = nameDateFormatter.string(from: date)
        }
        
        return name
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
