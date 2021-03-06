//
//  NearbyLocksViewController.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/12/18.
//  Copyright © 2018 ColemanCDA. All rights reserved.
//

import Foundation
import Bluetooth
import GATT
import CoreLock
import LockKit

import UIKit
import CoreBluetooth
import DarwinGATT
import AVFoundation
import Intents
import JGProgressHUD
import OpenCombine
import Combine

final class NearbyLocksViewController: UITableViewController {
    
    typealias Peripheral = NativeCentral.Peripheral
    
    // MARK: - Properties
    
    private var items = [LockPeripheral<NativeCentral>]() {
        didSet { tableView.reloadData() }
    }
    
    internal var progressHUD: JGProgressHUD?
    
    @available(iOS 10.0, *)
    private lazy var selectionFeedbackGenerator: UISelectionFeedbackGenerator = {
        let feedbackGenerator = UISelectionFeedbackGenerator()
        feedbackGenerator.prepare()
        return feedbackGenerator
    }()
    
    @available(iOS 10.0, *)
    private lazy var impactFeedbackGenerator: UIImpactFeedbackGenerator = {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        return feedbackGenerator
    }()
    
    private var peripheralsObserver: OpenCombine.AnyCancellable?
    private var informationObserver: OpenCombine.AnyCancellable?
    private var locksObserver: OpenCombine.AnyCancellable?
    @available(iOS 13.0, *)
    private lazy var updateTableViewSubject = Combine.PassthroughSubject<Void, Never>()
    private var updateTableViewObserver: AnyObject? // AnyCancellable
    
    // MARK: - Loading

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register cell
        tableView.register(LockTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
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
        
        // Update UI
        configureView()
        
        #if !targetEnvironment(macCatalyst)
        // scan if none is setup
        if Store.shared.locks.value.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0,
                                          execute: { [weak self] in self?.scan() })
        }
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 10.0, *) {
            selectionFeedbackGenerator.prepare()
            impactFeedbackGenerator.prepare()
        }
        
        #if targetEnvironment(macCatalyst)
        scan()
        #else
        if Store.shared.lockManager.central.state == .poweredOn,
            Store.shared.locks.value.isEmpty || Store.shared.lockInformation.value.isEmpty {
            scan()
        } else {
            // Update beacon status
            BeaconController.shared.scanBeacons()
        }
        #endif
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        userActivity = NSUserActivity(.screen(.nearbyLocks))
        userActivity?.becomeCurrent()
        
        #if targetEnvironment(macCatalyst)
        syncCloud()
        #endif
    }
    
    // MARK: - Actions
    
    @IBAction func scan(_ sender: NSObject) {
        
        if #available(iOS 10.0, *) {
            impactFeedbackGenerator.impactOccurred()
        }
        
        scan()
    }
    
    // MARK: - Methods
    
    private func locksChanged() {
        if #available(iOS 13.0, *) {
            updateTableViewSubject.send()
        } else {
            mainQueue { [weak self] in self?.configureView() }
        }
    }
    
    private func scan() {
        
        self.refreshControl?.endRefreshing()
        
        /// ignore if off or not authorized
        guard LockManager.shared.central.state == .poweredOn
            else { return } // cannot scan
        
        userActivity = NSUserActivity(.screen(.nearbyLocks))
        userActivity?.becomeCurrent()
        
        // refresh iBeacons in background
        BeaconController.shared.scanBeacons()
        
        // scan
        performActivity(queue: .bluetooth, {
            try Store.shared.scan()
            for peripheral in Store.shared.peripherals.value.values {
                do { try Store.shared.readInformation(peripheral) }
                catch {
                    log("⚠️ Could not read information for peripheral \(peripheral.scanData.peripheral)")
                    // try again
                    mainQueue { [weak self] in self?.scan() }
                }
            }
        })
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(LockTableViewCell.self, for: indexPath)
            else { fatalError("Could not dequeue reusable cell \(LockTableViewCell.self)") }
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        let item = self[indexPath]
        select(item)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        let lock = self[indexPath]
        guard let information = Store.shared.lockInformation.value[lock.scanData.peripheral]
            else { assertionFailure(); return }
        view(lock: information.identifier)
    }
    
    // MARK: - Private Methods
    
    private subscript (indexPath: IndexPath) -> LockPeripheral<NativeCentral> {
        return items[indexPath.row]
    }
    
    private func configureView() {
        
        // sort by signal
        self.items = Store.shared.peripherals.value.values
            .sorted(by: { $0.scanData.rssi < $1.scanData.rssi })
    }
    
    private func configure(cell: LockTableViewCell, at indexPath: IndexPath) {
        
        let lock = self[indexPath]
        
        let title: String
        let detail: String
        let permission: PermissionType?
        let isEnabled: Bool
        let showDetail: Bool
        
        if let information = Store.shared.lockInformation.value[lock.scanData.peripheral] {
            
            isEnabled = true
            
            if cell.activityIndicatorView.isAnimating {
                cell.activityIndicatorView.stopAnimating()
                cell.activityIndicatorView.isHidden = true
            }
            
            switch information.status {
                
            case .unlock:
                
                // known lock
                if let lockCache = Store.shared[lock: information.identifier] {
                    permission = lockCache.key.permission.type
                    title = lockCache.name
                    detail = lockCache.key.permission.localizedText
                    showDetail = true
                } else {
                    title = R.string.nearbyLocksViewController.lockTitleDefault() // "Lock"
                    detail = information.identifier.description
                    permission = .anytime
                    showDetail = false
                }
                
            case .setup:
                
                title = R.string.nearbyLocksViewController.lockTitleSetup() // "Setup"
                detail = information.identifier.description
                permission = .owner
                showDetail = false
            }
        } else {
            
            isEnabled = false
            title =  R.string.nearbyLocksViewController.lockTitleLoading() // "Loading..."
            detail = ""
            permission = nil
            showDetail = false
            
            if cell.activityIndicatorView.isHidden {
                cell.activityIndicatorView.isHidden = false
            }
            if cell.activityIndicatorView.isAnimating == false {
                cell.activityIndicatorView.startAnimating()
            }
        }
        
        cell.lockTitleLabel.text = title
        cell.lockDetailLabel.text = detail
        if let permission = permission {
            cell.permissionView.permission = permission
        }
        
        // hide image if loading
        cell.permissionView.isHidden = permission == nil
        cell.selectionStyle = isEnabled ? .default : .none
        cell.accessoryType = showDetail ? .detailDisclosureButton : .none
    }
    
    private func select(_ lock: LockPeripheral<NativeCentral>) {
        
        guard let information = Store.shared.lockInformation.value[lock.scanData.peripheral]
            else { return }
        
        let identifier = information.identifier
        
        log("Selected lock \(identifier)")
        
        if #available(iOS 10.0, *) {
            selectionFeedbackGenerator.selectionChanged()
        }
        
        switch information.status {
        case .setup:
            #if targetEnvironment(macCatalyst)
            showErrorAlert("Cannot setup on macOS.")
            #elseif targetEnvironment(simulator)
            showErrorAlert("Cannot setup in iOS simulator")
            #else
            setup(lock: lock)
            #endif
        case .unlock:
            if let _ = Store.shared[lock: identifier] {
                donateUnlockIntent(for: identifier)
                unlock(lock: lock)
            } else {
                showErrorAlert(LockError.noKey(lock: identifier).localizedDescription)
            }
        }
    }
}

// MARK: - ActivityIndicatorViewController

extension NearbyLocksViewController: ProgressHUDViewController { }
