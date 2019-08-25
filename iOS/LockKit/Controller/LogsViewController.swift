//
//  LogsViewController.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit

public final class LogsViewController: UITableViewController {
    
    // MARK: - Properties
    
    private(set) var items = [Log]() {
        didSet { configureView() }
    }
    
    public var store: Log.Store = .lockAppGroup {
        didSet { reloadData() }
    }
    
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    // MARK: - Loading
    
    public static func fromStoryboard() -> LogsViewController {
        guard let viewController = R.storyboard.logs.logsViewController()
            else { fatalError("Could not load view controller \(self) from storyboard") }
        return viewController
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure table view
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        
        if #available(iOS 11.0, *) {
            tableView.dragDelegate = self
        }
        
        // load logs
        reloadData()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadData()
    }
    
    // MARK: - Methods
    
    private subscript (indexPath: IndexPath) -> Log {
        get { return items[indexPath.row] }
    }
    
    private func reloadData() {
        
        do { try store.load() }
        catch { assertionFailure("Could not load logs: \(error)"); return }
        self.items = store.items
    }
    
    private func configureView() {
        
        loadViewIfNeeded()
        tableView.reloadData()
    }
    
    private func configure(cell: UITableViewCell, at indexPath: IndexPath) {
        
        let log = self[indexPath]
        if let metadata = log.metadata {
            cell.textLabel?.text = metadata.bundle.symbol + " " + metadata.bundle.localizedText
            cell.detailTextLabel?.text = dateFormatter.string(from: metadata.created)
        } else {
            cell.textLabel?.text = log.url.lastPathComponent.replacingOccurrences(of: "." + Log.fileExtension, with: "")
            cell.detailTextLabel?.text = nil
        }
    }
    
    private func select(_ item: Log) {
        
        let viewController = LogViewController.fromStoryboard(with: item)
        show(viewController, sender: self)
    }
    
    // MARK: - UITableViewDataSource
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.logTableViewCell, for: indexPath)!
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        
        let item = self[indexPath]
        select(item)
    }
}

// MARK: - UITableViewDragDelegate

@available(iOS 11.0, *)
extension LogsViewController: UITableViewDragDelegate {
    
    private func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
        
        let document = self[indexPath]
        
        guard let itemProvider = NSItemProvider(contentsOf: document.url)
            else { return [] }
        
        itemProvider.suggestedName = document.url.lastPathComponent
        
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = document
        return [dragItem]
    }
    
    public func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        return dragItems(for: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        
        return dragItems(for: indexPath)
    }
}
