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
        didSet { logChanged() }
    }
    
    public var logDateFormatter: DateFormatter = LogViewController.logDateFormatter {
        didSet { logChanged() }
    }
    
    private var items = [Item]() {
        didSet { configureTableView() }
    }
    
    private lazy var nameDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    private var timer: Timer?
    
    private lazy var queue = DispatchQueue(for: LogViewController.self, in: .app, qualityOfService: .userInteractive, isConcurrent: false)
    
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
        logChanged()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 13.0, iOSApplicationExtension 13.0, *) {
            let appearance = UINavigationBar.appearance().scrollEdgeAppearance?.copy() ?? .init()
            appearance.configureWithTransparentBackground()
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if #available(iOS 13.0, iOSApplicationExtension 13.0, *) {
            if let appearance = UINavigationBar.appearance().scrollEdgeAppearance {
                self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func share(_ sender: UIBarButtonItem) {
        
        let activityViewController = UIActivityViewController(activityItems: [log.url],
                                                              applicationActivities: nil)
        
        self.present(activityViewController, sender: .barButtonItem(sender))
    }
    
    // MARK: - Private Methods
    private subscript (indexPath: IndexPath) -> Item {
        get { return items[indexPath.row] }
    }
    
    private func configureView() {
        
        loadViewIfNeeded()
        
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
    
    private func logChanged() {
        loadViewIfNeeded()
        items.removeAll(keepingCapacity: true)
        configureView()
        reloadData()
    }
    
    private func reloadData() {
        
        queue.async { [weak self] in
            guard let self = self else { return }
            var text: String = ""
            do { text = try self.log.load() }
            catch { assertionFailure("Unable to load log: \(error)"); return }
            // parse into lines
            let newItems: [Item] = text
                .components(separatedBy: "\n")
                .filter { $0.isEmpty == false }
                .map { self.log(for: $0) }
            // update table view
            mainQueue { [weak self] in
                guard let self = self else { return }
                // update UI
                guard self.items != newItems else { return }
                let oldCount = self.items.count
                let newCount = newItems.count
                self.items = newItems
                // scroll to bottom if logs are being updated in real time.
                let lastIndexPath = IndexPath(row: self.items.count - 1, section: 0)
                if oldCount != newCount, oldCount > 1 {
                    self.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
                }
            }
        }
    }
    
    private func configure(cell: LogTableViewCell, at indexPath: IndexPath) {
        
        let item = self[indexPath]
        
        let dateText = item.date.flatMap({ logDateFormatter.string(from: $0) })
        cell.contentLabel.text = item.text
        cell.dateLabel.text = dateText
        cell.dateLabel.isHidden = dateText == nil
    }
    
    private func log(for string: String) -> Item {
        // FIXME: Optimize date parsing
        let components = string.components(separatedBy: " ")
        guard components.count >= 2 else {
            return Item(text: string, date: nil)
        }
        let dateString = components[0] + " " + components[1]
        guard let date = Log.dateFormatter.date(from: dateString) else {
            return Item(text: string, date: nil)
        }
        return Item(text: string.replacingOccurrences(of: dateString, with: ""), date: date)
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

private extension LogViewController {
    
    static let logDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.timeZone = .autoupdatingCurrent
        return dateFormatter
    }()
}

// MARK: - Supporting Types

private extension LogViewController {
    
    struct Item: Equatable, Hashable {
        let text: String
        let date: Date?
    }
}

public final class LogTableViewCell: UITableViewCell {
    
    @IBOutlet private(set) weak var dateLabel: UILabel!
    @IBOutlet private(set) weak var contentLabel: UILabel!
}
