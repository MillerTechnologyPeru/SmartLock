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
import OpenCombine
import Combine

final class TodayViewController: UIViewController, NCWidgetProviding {
    
    // MARK: - IB Outlets
    
    @IBOutlet private(set) weak var tableView: UITableView!
    
    // MARK: - Properties
    
    private(set) var items: [Item] = [.loading] {
        didSet { tableView.reloadData() }
    }
    
    private(set) var isScanning = true
    
    @available(iOS 10.0, *)
    private lazy var selectionFeedbackGenerator: UISelectionFeedbackGenerator = {
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.prepare()
        return feedbackGenerator
    }()
    
    private var peripheralsObserver: OpenCombine.AnyCancellable?
    private var informationObserver: OpenCombine.AnyCancellable?
    private var locksObserver: OpenCombine.AnyCancellable?
    @available(iOS 13.0, *)
    private lazy var updateTableViewSubject = Combine.PassthroughSubject<Void, Never>()
    private var updateTableViewObserver: AnyObject? // Combine.AnyCancellable
    
    // MARK: - Loading
        
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
        tableView.tableFooterView = UIView()
        
        // Set Logging
        LockManager.shared.log = { log("🔒 LockManager: " + $0) }
        BeaconController.shared.log = { log("📶 \(BeaconController.self): " + $0) }
        
        // observe model changes
        peripheralsObserver = Store.shared.peripherals.sink { [weak self] _ in
            self?.locksChanged()
        }
        informationObserver = Store.shared.lockInformation.sink { [weak self] _ in
            self?.locksChanged()
        }
        locksObserver = Store.shared.locks.sink { [weak self] _ in
            self?.locksChanged()
        }
        
        if #available(iOS 13.0, *) {
            updateTableViewObserver = updateTableViewSubject
                .delay(for: 1.0, scheduler: DispatchQueue.main)
                .sink(receiveValue: { [weak self] in self?.configureView() })
        }
        
        // update UI
        configureView()
        
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
        
        // load updated lock information
        Store.shared.loadCache()
        
        if #available(iOS 10.0, *) {
            selectionFeedbackGenerator.prepare()
        }
        
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        scan { completionHandler($0 ? .newData : .failed) }
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
    
    private func locksChanged() {
        if #available(iOS 13.0, *) {
            updateTableViewSubject.send()
        } else {
            mainQueue { [weak self] in self?.configureView() }
        }
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
        
        if locks.isEmpty {
            items = [isScanning ? .loading : .noNearbyLocks]
        } else {
            items = locks.map { .lock($0.identifier, $0.cache) }
        }
        
        // Show expanded view for multiple devices
        extensionContext?.widgetLargestAvailableDisplayMode = items.count > 1 ? .expanded : .compact
    }
    
    private func scan(_ completion: ((Bool) -> ())? = nil) {
        
        self.items = [.loading]
        
        // scan beacons
        BeaconController.shared.scanBeacons()
        
        // scan for devices
        DispatchQueue.bluetooth.async {
            do { try Store.shared.scan(duration: 1.0) }
            catch {
                log("⚠️ Could not scan: \(error.localizedDescription)")
                mainQueue { completion?(false) }
                return
            }
            mainQueue { completion?(true) }
        }
    }
    
    private func configure(cell: LockTableViewCell, at indexPath: IndexPath) {
        
        let item = self[indexPath]
        
        switch item {
        case .loading:
            cell.lockTitleLabel.text = "Loading..."
            cell.lockDetailLabel.text = nil
            cell.activityIndicatorView.isHidden = false
            if cell.activityIndicatorView.isAnimating == false {
                cell.activityIndicatorView.startAnimating()
            }
            cell.permissionView.isHidden = true
            cell.selectionStyle = .none
            cell.accessoryType = .none
        case .noNearbyLocks:
            cell.lockTitleLabel.text = "No Nearby Locks"
            cell.lockDetailLabel.text = nil
            cell.activityIndicatorView.isHidden = true
            cell.permissionView.isHidden = true
            cell.selectionStyle = .none
            cell.accessoryType = .none
        case let .lock(_, cache):
            let permission = cache.key.permission
            cell.lockTitleLabel.text = cache.name
            cell.lockDetailLabel.text = permission.localizedText
            cell.permissionView.permission = permission.type
            cell.activityIndicatorView.isHidden = true
            cell.permissionView.isHidden = false
            cell.selectionStyle = .default
            cell.accessoryType = .detailButton
        }
    }
    
    private func select(_ item: Item) {
        
        if #available(iOSApplicationExtension 10.0, *) {
            selectionFeedbackGenerator.selectionChanged()
        }
        
        switch item {
        case .loading:
            break
        case .noNearbyLocks:
            scan()
        case let .lock(identifier, cache):
            // unlock
            DispatchQueue.bluetooth.async {
                log("Unlock \(cache.name) \(identifier)")
                do {
                    guard let peripheral = Store.shared.device(for: identifier)
                        else { assertionFailure("Peripheral not found"); return }
                    try Store.shared.unlock(peripheral)
                } catch {
                    log("⚠️ Could not unlock: \(error.localizedDescription)")
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
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        let item = self[indexPath]
        guard case let .lock(identifier, _) = item
            else { assertionFailure(); return }
        let url = LockURL.unlock(lock: identifier)
        self.extensionContext?.open(url.rawValue, completionHandler: nil)
    }
}

// MARK: - Supporting Types

extension TodayViewController {
    
    enum Item: Equatable {
        
        case loading
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
