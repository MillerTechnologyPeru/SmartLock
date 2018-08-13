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
#endif

final class NearbyLocksViewController: UITableViewController {
    
    typealias Peripheral = NativeCentral.Peripheral
    
    // MARK: - Properties
    
    private var items = [Peripheral]() {
        
        didSet { configureView() }
    }
    
    let scanDuration: TimeInterval = 5.0
    
    // MARK: - Loading

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        scan()
    }
    
    // MARK: - Actions
    
    @IBAction func scan(_ sender: Any? = nil) {
        
        self.refreshControl?.endRefreshing()
        
        let scanDuration = self.scanDuration
        
        // reset table
        self.items.removeAll()
        
        // scan
        performActivity({
            
            try LockManager.shared.scan(duration: scanDuration, filterDuplicates: false) { (peripheral) in
                
                mainQueue { [weak self] in self?.items.append(peripheral) }
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
}

// MARK: - ActivityIndicatorViewController

extension NearbyLocksViewController: ActivityIndicatorViewController { }

