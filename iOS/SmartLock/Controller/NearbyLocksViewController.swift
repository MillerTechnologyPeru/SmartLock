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
import CoreBluetooth
import DarwinGATT
import AVFoundation
import QRCodeReader
import JGProgressHUD
#endif

final class NearbyLocksViewController: UITableViewController {
    
    typealias Peripheral = NativeCentral.Peripheral
    
    // MARK: - Properties
    
    private var items = [Peripheral]() {
        
        didSet { configureView() }
    }
    
    let scanDuration: TimeInterval = 2.0
    
    #if os(iOS)
    
    internal lazy var progressHUD: JGProgressHUD = JGProgressHUD(style: .dark)
    
    private lazy var readerViewController: QRCodeReaderViewController = {
        
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    #endif
    
    // MARK: - Loading

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
        
        // try to scan
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: { [weak self] in self?.scan() })
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
        self.items.removeAll()
        
        // scan
        performActivity({
            
            try LockManager.shared.scan(duration: scanDuration, filterDuplicates: false) { (peripheral) in
                
                mainQueue { [weak self] in
                    
                    guard let controller = self else { return }
                    
                    if controller.items.contains(peripheral) == false {
                        
                        controller.items.append(peripheral)
                    }
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralCell", for: indexPath)
        
        configure(cell: cell, at: indexPath)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        
        let peripheral = self[indexPath]
        
        selectLock(peripheral)
    }
    
    // MARK: - Private Methods
    
    private subscript (indexPath: IndexPath) -> Peripheral {
        
        return items[indexPath.row]
    }
    
    private func configureView() {
        
        tableView.reloadData()
    }
    
    private func configure(cell: UITableViewCell, at indexPath: IndexPath) {
        
        let item = self[indexPath]
        
        cell.textLabel?.text = item.identifier.description
    }
    
    private func selectLock(_ peripheral: Peripheral) {
        
        performActivity({
            
            let information = try LockManager.shared.readInformation(for: peripheral)
            
            log("Selected lock \(information)")
            
            // attempt to unlock if key is stored.
            if let lockCache = Store.shared[lock: information.identifier] {
                
                
                
            } else {
                
                
            }
            
            
            
            
            
            switch information.status {
                
            case .setup:
                
                mainQueue { [weak self] in self?.setupLock(peripheral) }
                
            case .unlock:
                
                break
                //try LockManager.shared.unlock(key: (identifier: UUID, secret: KeyData), peripheral: peripheral)
            }
        })
    }
    
    private func unlock(_ peripheral: Peripheral) {
        
        
    }
    
    private func setupLock(_ peripheral: Peripheral) {
        
        // scan QR code
        assert(QRCodeReader.isAvailable())
        
        readerViewController.completionBlock = { [unowned self] (result: QRCodeReaderResult?) in
            
            // did not scan
            guard let result = result else { return }
            
            self.readerViewController.dismiss(animated: true, completion: {
                
                guard let data = Data(base64Encoded: result.value),
                    let key = KeyData(data: data) else {
                    
                    self.showErrorAlert("Invalid QR code")
                    return
                }
                
                // perform BLE request
                self.setupLock(peripheral, with: key)
            })
        }
        
        // Presents the readerVC as modal form sheet
        readerViewController.modalPresentationStyle = .formSheet
        present(readerViewController, animated: true, completion: nil)
    }
    
    private func setupLock(_ peripheral: Peripheral, with sharedSecret: KeyData) {
        
        performActivity({
            
            let request = SetupRequest()
            
            let information = try LockManager.shared.setup(peripheral: peripheral,
                                                           with: request,
                                                           sharedSecret: sharedSecret)
            
            // store new key
            log("Setup with key \(request.identifier)")
            
            
            
            //Store.shared[lock: information.identifier] = LockCache(key: <#T##Key#>, name: <#T##String#>)
            
            mainQueue { [weak self] in
                
                
            }
        })
    }
}

// MARK: - ActivityIndicatorViewController

extension NearbyLocksViewController: ActivityIndicatorViewController { }
