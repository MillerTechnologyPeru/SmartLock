//
//  LogViewController.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

/// Log View Controller
public final class LogViewController: UITableViewController {
    
    // MARK: - Properties
    
    public var log: Log = .shared {
        didSet { reloadData() }
    }
    
    private var items = [String]() {
        didSet { configureTableView() }
    }
    
    private var textCache: String = ""
    
    private lazy var nameDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    private var timer: Timer?
    
    private lazy var queue = DispatchQueue(label: "com.colemancda.Lock.Logs")
    
    // MARK: - Loading
    
    public static func fromStoryboard(with log: Log = .shared) -> LogViewController {
        let viewController = R.storyboard.logs.logViewController()!
        viewController.log = log
        return viewController
    }
    
    deinit {
        timer?.invalidate()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure table view
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        
        // update logs
        if #available(iOS 10, iOSApplicationExtension 10.0, *) {
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                self?.reloadData()
            }
        }
        
        // load log
        reloadData()
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
        self.configureTableView()
    }
    
    private func configureTableView() {
        self.tableView.reloadData()
    }
    
    private func reloadData() {
        
        queue.async { [weak self] in
            guard let self = self else { return }
            var text: String = ""
            do { text = try self.log.load() }
            catch { assertionFailure("Unable to load log: \(error)"); return }
            // reload if different
            guard text != self.textCache
                else { return }
            self.textCache = text
            // parse into lines
            let items: [String] = text
                .components(separatedBy: "\n")
                .filter { $0.isEmpty == false }
            mainQueue {
                // update UI
                self.items = items
            }
        }
    }

    private func configure(cell: UITableViewCell, at indexPath: IndexPath) {
        
        let item = self[indexPath]
        cell.textLabel?.text = item
    }
    
    // MARK: - UITableViewDataSource
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.logEntryTableViewCell, for: indexPath)!
        configure(cell: cell, at: indexPath)
        return cell
    }
}
