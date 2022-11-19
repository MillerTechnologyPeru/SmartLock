//
//  InterfaceController.swift
//  Watch Extension
//
//  Created by Alsey Coleman Miller on 8/28/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import WatchKit
import CoreLock
import LockKit
import Combine

final class InterfaceController: WKInterfaceController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private(set) weak var tableView: WKInterfaceTable!
    
    @IBOutlet private(set) weak var activityImageView: WKInterfaceImage?
    
    @IBOutlet private(set) weak var contentGroup: WKInterfaceGroup!
    
    @IBOutlet private(set) weak var scanButton: WKInterfaceButton!
    
    // MARK: - Properties
    
    let activity = NSUserActivity(.screen(.nearbyLocks))
        
    private var items = [Item]()
    
    private var peripheralsObserver: AnyCancellable?
    private var informationObserver: AnyCancellable?
    private var locksObserver: AnyCancellable?
    
    // MARK: - Loading

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Observe changes
        peripheralsObserver = Store.shared.$peripherals.sink { [weak self] _ in
            mainQueue { self?.configureView() }
        }
        informationObserver = Store.shared.$lockInformation.sink { [weak self] _ in
            mainQueue { self?.configureView() }
        }
        locksObserver = Store.shared.$locks.sink { [weak self] _ in
            mainQueue { self?.configureView() }
        }
        
        // Configure interface objects here.
        setupActivityImageView()
        
        // update UI
        configureView()
        
        // scan for locks
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if Store.shared.lockInformation.isEmpty {
                self?.scan()
            }
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
                
        activity.becomeCurrent()
        
        // sync with app if nearby and never updated
        if Store.shared.preferences.lastWatchUpdate == nil,
            SessionController.shared.isReachable {
            Store.shared.syncApp()
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
        activity.invalidate()
    }
    
    // MARK: - Actions
    
    @IBAction func scan(_ sender: NSObject) {
        
        WKInterfaceDevice.current().play(.click)
        scan()
    }
    
    // MARK: - Methods
    
    private func scan() {
        
        // sync with app if nearby and never updated
        if Store.shared.preferences.lastWatchUpdate == nil,
            SessionController.shared.isReachable {
            Store.shared.syncApp()
        }
        
        Task {
            /// ignore if off or not authorized
            guard await Store.shared.central.state == .poweredOn
                else { return } // cannot scan
            
            await MainActor.run {
                activity.becomeCurrent()
            }
            
            // scan
            performActivity({
                try await Store.shared.scan()
                for peripheral in Store.shared.peripherals.keys {
                    do { try await Store.shared.readInformation(peripheral) }
                    catch { log("⚠️ Could not read information for peripheral \(peripheral)") }
                }
            })
        }
        
    }
    
    private func configureView() {
        
        self.items = Store.shared.peripherals.values
            .lazy
            .sorted { $0.rssi < $1.rssi }
            .map { $0.peripheral }
            .compactMap { (peripheral) in
                Store.shared.lockInformation[peripheral].flatMap { (information) in
                    Store.shared[lock: information.id].flatMap { (cache) in
                        Item(id: information.id, cache: cache, peripheral: peripheral)
                    }
                }
            }
        
        if items.isEmpty == false {
            hideActivity()
        }
        
        self.tableView.setNumberOfRows(items.count, withRowType: LockRowController.rowType)
        
        for (index, lock) in items.enumerated() {
            
            let rowController = self.tableView.rowController(at: index) as! LockRowController
            let image: UIImage
            switch lock.cache.key.permission {
            case .owner: image = #imageLiteral(resourceName: "watchOwner")
            case .admin: image = #imageLiteral(resourceName: "watchAdmin")
            case .anytime: image = #imageLiteral(resourceName: "watchAnytime")
            case .scheduled: image = #imageLiteral(resourceName: "watchScheduled")
            }
            rowController.imageView.setImage(image)
            rowController.label.setText(lock.cache.name)
        }
    }
    
    private func select(_ item: Item) {
        
        log("Selected lock \(item.id)")
        
        unlock(lock: item.id, peripheral: item.peripheral)
    }
    
    // MARK: - Segue
    
    override func contextForSegue(withIdentifier segueIdentifier: String, in table: WKInterfaceTable, rowIndex: Int) -> Any? {
        
        // let lock = locks[rowIndex]
        // return LockContext(lock: lock)
        return nil
    }
    
    // MARK: - Table View
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        
        let item = self.items[rowIndex]
        select(item)
    }
}

extension InterfaceController: ActivityInterface {
    
    var contentView: WKInterfaceObject {
        return contentGroup
    }
}

// MARK: - Supporting Types

private extension InterfaceController {
    
    struct Item: Equatable {
        
        let id: UUID
        let cache: LockCache
        let peripheral: NativeCentral.Peripheral
    }
}

// MARK: - Supporting Types

final class LockRowController: NSObject {
    
    static let rowType = "Lock"
    
    @IBOutlet private(set) weak var imageView: WKInterfaceImage!
    
    @IBOutlet private(set) weak var label: WKInterfaceLabel!
}
