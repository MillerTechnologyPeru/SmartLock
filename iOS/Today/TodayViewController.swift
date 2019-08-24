//
//  TodayViewController.swift
//  Today
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import NotificationCenter
import CoreBluetooth
import Bluetooth
import GATT
import DarwinGATT
import CoreLock
import LockKit

final class TodayViewController: UIViewController, NCWidgetProviding {
    
    // MARK: - IB Outlets
    
    @IBOutlet private(set) weak var tableView: UITableView!
    
    // MARK: - Properties
    
    private(set) var items: [Item] = [.noNearbyLocks]
    
    private var peripheralsObserver: Int?
    private var informationObserver: Int?
    private var locksObserver: Int?
    
    @available(iOS 10.0, *)
    private lazy var selectionFeedbackGenerator: UISelectionFeedbackGenerator = {
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.prepare()
        return feedbackGenerator
    }()
    
    // MARK: - Loading
    
    deinit {
        
        if let observer = peripheralsObserver {
            Store.shared.peripherals.remove(observer: observer)
        }
        if let observer = informationObserver {
            Store.shared.lockInformation.remove(observer: observer)
        }
        if let observer = locksObserver {
            Store.shared.locks.remove(observer: observer)
        }
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure logging
        Log.shared = .today
        
        // set global appearance
        UIView.configureLockAppearance()
        
        log("☀️ Loaded \(TodayViewController.self)")
        
        // register cell
        tableView.register(LockTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        // Set Logging
        LockManager.shared.log = { log("🔒 LockManager: " + $0) }
        BeaconController.shared.log = { log("📶 \(BeaconController.self): " + $0) }
        
        // scan beacons
        BeaconController.shared.scanBeacons()
        
        // Observe changes
        peripheralsObserver = Store.shared.peripherals.observe { [weak self] _ in
            mainQueue { self?.configureView() }
        }
        informationObserver = Store.shared.lockInformation.observe { [weak self] _ in
            mainQueue { self?.configureView() }
        }
        locksObserver = Store.shared.locks.observe { [weak self] _ in
            mainQueue { self?.configureView() }
        }
        
        // update UI
        configureView()
        
        // scan for locks
        if Store.shared.lockInformation.value.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.reloadData()
            }
        }
        
        if #available(iOS 10.0, *) {
            selectionFeedbackGenerator.prepare()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 10.0, *) {
            selectionFeedbackGenerator.prepare()
        }
    }
    
    // MARK: - NCWidgetProviding
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        
        log("☀️ Update Widget Data")
        
        if #available(iOS 10.0, *) {
            selectionFeedbackGenerator.prepare()
        }
        
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        reloadData { completionHandler($0 ? .newData : .failed) }
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        
        log("☀️ Widget Display Mode changed \(activeDisplayMode.debugDescription) \(maxSize)")
        
        
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return .zero
    }
    
    // MARK: - Methods
    
    private subscript (indexPath: IndexPath) -> Item {
        
        @inline(__always)
        get { return items[indexPath.row] }
    }
    
    private func configureView() {
        
        let locks = Store.shared.peripherals.value.values
            .lazy
            .sorted { $0.scanData.rssi < $1.scanData.rssi }
            .lazy
            .compactMap { Store.shared.lockInformation.value[$0.scanData.peripheral] }
            .lazy
            .compactMap { information in
                Store.shared[lock: information.identifier]
                    .flatMap { (identifier: information.identifier, cache: $0) }
        }
        
        let oldItems = self.items
        if locks.isEmpty {
            items = [.noNearbyLocks]
        } else {
            items = locks.map { .lock($0.identifier, $0.cache) }
        }
        
        // reload table view
        if oldItems != items {
            tableView.reloadData()
        }
    }
    
    private func reloadData(_ completion: ((Bool) -> ())? = nil) {
        
        // scan beacons
        BeaconController.shared.scanBeacons()
        
        // scan for devices
        async {
            log("Scanning...")
            do { try Store.shared.scan(duration: 1.0) }
            catch {
                log("⚠️ Could not scan: \(error)")
                mainQueue { completion?(false) }
                return
            }
            mainQueue { completion?(true) }
        }
    }
    
    private func configure(cell: LockTableViewCell, at indexPath: IndexPath) {
        
        let item = self[indexPath]
        
        switch item {
        case .noNearbyLocks:
            cell.lockTitleLabel.text = "No Nearby Locks"
            cell.lockDetailLabel.text = nil
            cell.lockImageView.image = nil
            cell.activityIndicatorView.isHidden = true
            cell.lockImageView.isHidden = true
            cell.selectionStyle = .none
        case let .lock(_, cache):
            let permission = cache.key.permission
            cell.lockTitleLabel.text = cache.name
            cell.lockDetailLabel.text = permission.localizedText
            cell.lockImageView.image = UIImage(permission: permission)
            cell.activityIndicatorView.isHidden = true
            cell.lockImageView.isHidden = false
            cell.selectionStyle = .default
        }
    }
    
    private func select(_ item: Item) {
        
        if #available(iOSApplicationExtension 10.0, *) {
            selectionFeedbackGenerator.selectionChanged()
        }
        
        switch item {
        case .noNearbyLocks:
            reloadData()
        case let .lock(identifier, cache):
            // unlock
            async {
                log("Unlock \(cache.name) \(identifier)")
                do {
                    guard let peripheral = Store.shared.device(for: identifier)
                        else { assertionFailure("Peripheral not found"); return }
                    try Store.shared.unlock(peripheral)
                } catch {
                    log("⚠️ Could not unlock: \(error)")
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension TodayViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(LockTableViewCell.self, for: indexPath)
            else { fatalError("Could not dequeue resusable cell \(LockTableViewCell.self)") }
        configure(cell: cell, at: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TodayViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        let item = self[indexPath]
        select(item)
    }
}

// MARK: - Supporting Types

extension TodayViewController {
    
    enum Item: Equatable {
        
        case noNearbyLocks
        case lock(UUID, LockCache)
    }
}

@available(iOSApplicationExtension 10.0, *)
extension NCWidgetDisplayMode {
    
    var debugDescription: String {
        
        switch self {
        case .compact:
            return "compact"
        case .expanded:
            return "expanded"
        @unknown default:
            assertionFailure()
            return "Display Mode \(rawValue)"
        }
    }
}

// MARK: - Logging

extension Log {
    
    static var today: Log {
        struct Cache {
            static let log: Log = {
                do { return try Log.Store.lockAppGroup.create(date: Date(), bundle: .init(for: TodayViewController.self)) }
                catch { assertionFailure("Could not create log file: \(error)"); return .appCache }
            }()
        }
        return Cache.log
    }
}
