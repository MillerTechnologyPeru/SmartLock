//
//  MessagesViewController.swift
//  Message
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import Messages
import CoreBluetooth
import Bluetooth
import GATT
import DarwinGATT
import CoreLock
import LockKit

final class MessagesViewController: MSMessagesAppViewController {
    
    // MARK: - IB Outlets
    
    @IBOutlet private(set) weak var tableView: UITableView!
    
    // MARK: - Properties
    
    private(set) var items = [Item]()
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure logging
        Log.shared = .message
        
        // set global appearance
        UIView.configureLockAppearance()
        
        // print extension info
        log("✉️ Loaded \(MessagesViewController.self)")
        
        // setup loading
        LockManager.shared.log = { log("🔒 LockManager: " + $0) }
        BeaconController.shared.log = { log("📶 \(BeaconController.self): " + $0) }
        SpotlightController.shared.log = { log("🔦 \(SpotlightController.self): " + $0) }
        
        // setup table view
        tableView.register(LockTableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        // load updated lock information
        Store.shared.loadCache()
        
        // update UI
        configureView()
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        log("✉️ Will become active")
        
        // load updated lock information
        Store.shared.loadCache()
        
        if let selectedMessage = conversation.selectedMessage {
            
            log("✉️ Selected message \(selectedMessage.url?.absoluteString ?? selectedMessage.description)")
            
            guard let messageURL = selectedMessage.url
                else { assertionFailure("No URL encoded in message"); return }
            
            let urlComponents = URLComponents(url: messageURL, resolvingAgainstBaseURL: false)
            
            if let urlString = urlComponents?.queryItems?.first(where: { $0.name == "url" })?.value?.removingPercentEncoding,
                let url = URL(string: urlString),
                let lockURL = LockURL(rawValue: url) {
                
                self.handle(url: lockURL)
            }
        }
        
        // Use this method to configure the extension and restore previously stored state.
        configureView()
    }
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
        
        log("✉️ Did resign active")
    }
    
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
        
        log("✉️ Did recieve \(message)")
        
        // load updated lock information
        Store.shared.loadCache()
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
        
         log("✉️ Did recieve \(message)")
        
        // load updated lock information
        Store.shared.loadCache()
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
        
        log("✉️ Did cancel sending \(message)")
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
        log("✉️ Will transition to \(presentationStyle.debugDescription)")
        
        switch presentationStyle {
        case .compact:
            // dismiss modal UI
            self.dismiss(animated: true, completion: nil)
        case .expanded:
            break
        case .transcript:
            break
        @unknown default:
            break
        }
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
        log("✉️ Did transition to \(presentationStyle.debugDescription)")
    }
    
    // MARK: - Methods
    
    private subscript (indexPath: IndexPath) -> Item {
        return items[indexPath.row]
    }
    
    private func configureView() {
        
        // load updated lock information
        Store.shared.loadCache()
        
        // set data
        self.items = Store.shared.locks.value
            .lazy
            .filter { $0.value.key.permission.isAdministrator }
            .lazy
            .map { Item(identifier: $0.key, cache: $0.value) }
            .sorted(by: { $0.cache.key.created < $1.cache.key.created })
        
        // update table view
        self.tableView.reloadData()
    }
    
    private func configure(cell: LockTableViewCell, at indexPath: IndexPath) {
        
        let item = self[indexPath]
        let permission = item.cache.key.permission
        
        cell.lockTitleLabel.text = item.cache.name
        cell.lockDetailLabel.text = permission.localizedText
        cell.permissionView.permission = permission.type
        cell.activityIndicatorView.isHidden = true
        cell.permissionView.isHidden = false
    }
    
    private func select(_ item: Item) {
        
        log("Selected \(item.cache.name) \(item.identifier)")
        
        requestPresentationStyle(.expanded)
        shareKey(lock: item.identifier) { [unowned self] in
            self.dismiss(animated: true, completion: nil)
            self.requestPresentationStyle(.compact)
            guard let invitation = $0?.invitation else {
                return
            }
            self.insertMessage(for: invitation)
        }
    }
    
    private func insertMessage(for invitation: NewKey.Invitation) {
        
        guard let conversation = activeConversation else { fatalError("Expected a conversation") }
        
        let lockURL = LockURL.newKey(invitation)
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "url", value: lockURL.rawValue.absoluteString)
        ]
        
        let layout = MSMessageTemplateLayout()
        layout.mediaFileURL = AssetExtractor.shared.url(for: invitation.key.permission.type.image)
        layout.caption = "Shared \(invitation.key.permission.type.localizedText) key"
        
        let message = MSMessage(session: activeConversation?.selectedMessage?.session ?? MSSession())
        message.url = components.url!
        message.layout = layout
        
        // Add the message to the conversation.
        conversation.insert(message) { [weak self] error in
            if let error = error {
                log("⚠️ Could not insert message: " + error.localizedDescription)
            } else {
                self?.dismiss()
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension MessagesViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(LockTableViewCell.self, for: indexPath)!
        configure(cell: cell, at: indexPath)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MessagesViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        defer { tableView.deselectRow(at: indexPath, animated: true) }
        let item = self[indexPath]
        select(item)
    }
}

// MARK: - LockActivityHandlingViewController

extension MessagesViewController: LockActivityHandlingViewController {
    
    func handle(url: LockURL) {
        
        switch url {
        case let .newKey(invitation):
            // open invitation
            open(newKey: invitation) { [weak self] _ in
                self?.requestPresentationStyle(.compact)
            }
            self.requestPresentationStyle(.expanded)
        default:
            // defer to app
            extensionContext?.open(url.rawValue, completionHandler: nil)
        }
    }
    
    func handle(activity: AppActivity) {
        assertionFailure("Cannot handle activity \(activity)")
    }
}

// MARK: - Supporting Types

extension MessagesViewController {
    
    struct Item {
        
        let id: UUID
        let cache: LockCache
    }
}

extension MSMessagesAppPresentationStyle {
    
    var debugDescription: String {
        
        switch self {
        case .compact:
            return "compact"
        case .expanded:
            return "expanded"
        case .transcript:
            return "transcript"
        @unknown default:
            assertionFailure("Unknown state \(rawValue)")
            return "Style \(rawValue)"
        }
    }
}

// MARK: - Logging

extension Log {
    
    static var message: Log {
        struct Cache {
            static let log: Log = {
                do { return try Log.Store.lockAppGroup.create(date: Date(), bundle: .init(for: MessagesViewController.self)) }
                catch { assertionFailure("Could not create log file: \(error)"); return .appCache }
            }()
        }
        return Cache.log
    }
}
