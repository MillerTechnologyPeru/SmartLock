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
    
    var items = [Log]() {
        didSet { configureView() }
    }
    
    private lazy var store: Log.Store = .lockAppGroup
    
    private lazy var nameDateFormatter: DateFormatter = {
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
    
    // MARK: - Private Methods
    private subscript (indexPath: IndexPath) -> Log {
        get { return items[indexPath.row] }
    }
    
    private func reloadData() {
        
        try! store.load()
        self.items = store.items.sorted(by: { $0.url.lastPathComponent > $1.url.lastPathComponent })
    }
    
    private func configureView() {
        
        tableView.reloadData()
    }
    

    private func configure(cell: UITableViewCell, with item: Log) {
        
        let name = self.name(for: item)
        
        cell.textLabel?.text = name
    }
    
    private func name(for log: Log) -> String {
        
        var name = log.url.lastPathComponent.replacingOccurrences(of: "." + Log.fileExtension, with: "")
        
        if let timeInterval = Int(name) {
            
            let date = Date(timeIntervalSince1970: TimeInterval(timeInterval))
            
            name = nameDateFormatter.string(from: date)
        }
        
        return name
    }
    
    private func select(_ item: Log) {
        
        let viewController = R.storyboard.logs.logViewController()!
        viewController.log = item
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
        
        let item = self[indexPath]
        configure(cell: cell, with: item)
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
        
        itemProvider.suggestedName = name(for: document)
        
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
