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
    
#if os(iOS)
import UIKit
import DarwinGATT
import AVFoundation
import QRCodeReader
import JGProgressHUD
#endif

final class NearbyLocksViewController: UITableViewController {
    
    typealias Peripheral = NativeCentral.Peripheral
    
    // MARK: - Properties
    
    private var items = [LockPeripheral<NativeCentral>]()
    
    private var loadedInformation = Set<NativeCentral.Peripheral>()
    private var loading = Set<NativeCentral.Peripheral>()
    
    let scanDuration: TimeInterval = 3.0
    
    #if os(iOS)
    
    internal lazy var progressHUD: JGProgressHUD = JGProgressHUD(style: .dark)
    
    private lazy var readerViewController: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        return QRCodeReaderViewController(builder: builder)
    }()
    
    #endif
    
    private var peripheralsObserver: Int?
    private var informationObserver: Int?
    private var locksObserver: Int?
    
    // MARK: - Loading
    
    deinit {
        
        if let observer = peripheralsObserver {
            Store.shared.peripherals.remove(observer: observer)
        }
        if let observer = informationObserver {
            Store.shared.lockInformation.remove(observer: observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // register cell
        tableView.register(LockTableViewCell.nib, forCellReuseIdentifier: LockTableViewCell.reuseIdentifier)
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
        
        // observe model changes
        peripheralsObserver = Store.shared.peripherals.observe { [weak self] _ in
            mainQueue { self?.configureView() }
        }
        informationObserver = Store.shared.lockInformation.observe { [weak self] _ in
            mainQueue { self?.configureView() }
        }
        informationObserver = Store.shared.locks.observe { [weak self] _ in
            mainQueue { self?.configureView() }
        }
        
        // Update UI
        configureView()
        
        // try to scan
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0,
                                      execute: { [weak self] in self?.scan() })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if items.isEmpty {
            scan()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func scan(_ sender: Any? = nil) {
        
        self.refreshControl?.endRefreshing()
        
        /// ignore if off or not authorized
        #if os(iOS)
        guard LockManager.shared.central.state == .poweredOn
            else { return } // cannot scan
        #endif
        
        let scanDuration = self.scanDuration
        
        // reset table
        self.items.removeAll(keepingCapacity: true)
        self.loadedInformation.removeAll(keepingCapacity: true)
        
        // scan
        performActivity({ try Store.shared.scan(duration: scanDuration) }) { (viewController, _) in
            if viewController.items.isEmpty { viewController.scan() } // scan again
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: LockTableViewCell.reuseIdentifier, for: indexPath) as! LockTableViewCell
        
        // read information
        let lock = self[indexPath]
        loadLockInformation(lock)
        
        // configure cell
        configure(cell: cell, at: indexPath)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        
        let item = self[indexPath]
        
        select(item)
    }
    
    // MARK: - Private Methods
    
    private subscript (indexPath: IndexPath) -> LockPeripheral<NativeCentral> {
        
        return items[indexPath.row]
    }
    
    private func configureView() {
        
        // sort by signal
        self.items = Store.shared.peripherals.value.values.sorted(by: { $0.scanData.rssi < $1.scanData.rssi })
        
        tableView.reloadData()
    }
    
    private func configure(cell: LockTableViewCell, at indexPath: IndexPath) {
        
        let lock = self[indexPath]
        let peripheral = lock.scanData.peripheral
        
        let title: String
        let detail: String
        let image: UIImage?
        let isEnabled: Bool
        
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
                    
                    let permission = lockCache.key.permission
                    let permissionImage: UIImage
                    let permissionText: String
                    
                    switch permission {
                    case .owner:
                        permissionImage = #imageLiteral(resourceName: "permissionBadgeOwner")
                        permissionText = "Owner"
                    case .admin:
                        permissionImage = #imageLiteral(resourceName: "permissionBadgeAdmin")
                        permissionText = "Admin"
                    case .anytime:
                        permissionImage = #imageLiteral(resourceName: "permissionBadgeAnytime")
                        permissionText = "Anytime"
                    case .scheduled:
                        permissionImage = #imageLiteral(resourceName: "permissionBadgeScheduled")
                        permissionText = "Scheduled" // FIXME: Localized Schedule text
                    }
                    
                    title = lockCache.name
                    detail = permissionText
                    image = permissionImage
                } else {
                    title = "Lock"
                    detail = information.identifier.description
                    image = #imageLiteral(resourceName: "permissionBadgeAnytime")
                }
                
            case .setup:
                
                title = "Setup"
                detail = information.identifier.description
                image = #imageLiteral(resourceName: "permissionBadgeOwner")
            }
        } else {
            
            isEnabled = false
            title = "Loading..."
            detail = ""
            image = nil
            
            if cell.activityIndicatorView.isHidden {
                cell.activityIndicatorView.isHidden = false
            }
            if cell.activityIndicatorView.isAnimating == false {
                cell.activityIndicatorView.startAnimating()
            }
        }
        
        cell.lockTitleLabel.text = title
        cell.lockDetailLabel.text = detail
        cell.lockImageView.image = image
        
        // hide image if loading
        cell.lockImageView.isHidden = image == nil
        
        cell.selectionStyle = isEnabled ? .default : .none
    }
    
    private func select(_ lock: LockPeripheral<NativeCentral>) {
        
        log("Selected peripheral \(lock.scanData.peripheral)")
        
        guard let information = Store.shared.lockInformation.value[lock.scanData.peripheral]
            else { return }
        
        switch information.status {
        case .setup:
            setup(lock)
        case .unlock:
            unlock(lock)
        }
    }
    
    private func loadLockInformation(_ lock: LockPeripheral<NativeCentral>) {
        
        let peripheral = lock.scanData.peripheral
        guard self.loadedInformation.contains(peripheral) == false,
            self.loading.contains(peripheral) == false
            else { return }
        
        self.loading.insert(peripheral)
        
        async {
            
            do { try Store.shared.readInformation(lock) }
            catch { log("Could not read information for peripheral \(peripheral): \(error)") }
            mainQueue {
                self.loadedInformation.insert(peripheral)
                self.loading.remove(peripheral)
            }
        }
    }
    
    private func unlock(_ lock: LockPeripheral<NativeCentral>) {
        
        guard let information = Store.shared.lockInformation.value[lock.scanData.peripheral],
            let lockCache = Store.shared[lock: information.identifier],
            let keyData = Store.shared[key: lockCache.key.identifier]
            else { return }
        
        let key = KeyCredentials(
            identifier: lockCache.key.identifier,
            secret: keyData
        )
        
        performActivity({ try LockManager.shared.unlock(.default,
                                                        for: lock.scanData.peripheral,
                                                        with: key,
                                                        timeout: .gattDefaultTimeout) })
    }
    
    private func setup(_ lock: LockPeripheral<NativeCentral>) {
        
        // scan QR code
        assert(QRCodeReader.isAvailable())
        
        readerViewController.completionBlock = { [unowned self] (result: QRCodeReaderResult?) in
            
            self.readerViewController.dismiss(animated: true, completion: {
                
                // did not scan
                guard let result = result else { return }
                
                guard let data = Data(base64Encoded: result.value),
                    let sharedSecret = KeyData(data: data) else {
                    
                    self.showErrorAlert("Invalid QR code")
                    return
                }
                
                // perform BLE request
                self.setupLock(lock, sharedSecret: sharedSecret)
            })
        }
        
        // Presents the readerVC as modal form sheet
        readerViewController.modalPresentationStyle = .formSheet
        present(readerViewController, animated: true, completion: nil)
    }
    
    private func setupLock(_ lock: LockPeripheral<NativeCentral>, sharedSecret: KeyData, name: String = "Lock") {
        
        performActivity({ try Store.shared.setup(lock, sharedSecret: sharedSecret, name: name) })
    }
}

// MARK: - ActivityIndicatorViewController

extension NearbyLocksViewController: ActivityIndicatorViewController { }
