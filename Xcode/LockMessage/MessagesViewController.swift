//
//  MessagesViewController.swift
//  LockMessage
//
//  Created by Alsey Coleman Miller on 9/27/22.
//

import Foundation
import Messages
import UIKit
import SwiftUI
import LockKit

final class MessagesViewController: MSMessagesAppViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let _ = Store.shared
        configureView()
        log("✉️ Loaded \(MessagesViewController.self)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        requestPresentationStyle(.compact)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        requestPresentationStyle(.expanded)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        log("✉️ Will become active")
        
        guard let selectedMessage = conversation.selectedMessage else {
            return
        }
        
        log("✉️ Selected message \(selectedMessage.url?.absoluteString ?? selectedMessage.description)")
        guard let messageURL = selectedMessage.url
            else { assertionFailure("No URL encoded in message"); return }
        let urlComponents = URLComponents(url: messageURL, resolvingAgainstBaseURL: false)
        
        guard let urlString = urlComponents?.queryItems?.first(where: { $0.name == "url" })?.value?.removingPercentEncoding,
            let url = URL(string: urlString),
            let lockURL = LockURL(rawValue: url) else {
           return
        }
        
        Task {
            await handle(url: lockURL)
        }
    }
    
    override func didResignActive(with conversation: MSConversation) {
        log("✉️ Did resign active")
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Use this method to trigger UI updates in response to the message.
        log("✉️ Did recieve \(message)")
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
        log("✉️ Did recieve \(message)")
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
            self.navigationController?.popToRootViewController(animated: true)
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
}

extension MessagesViewController {
    
    private func configureView() {
        
        let viewController = UIHostingController(
            rootView: MessagesView(
                didCreateKey: didCreateKey
            )
            .environmentObject(Store.shared)
        )
        
        loadChildViewController(viewController)
    }
    
    func handle(url: LockURL) async {
        
        switch url {
        case let .newKey(invitation):
            // open invitation
            self.open(invitation: invitation)
        default:
            // defer to app
            await extensionContext?.open(url.rawValue)
        }
    }
    
    func open(invitation: NewKey.Invitation) {
        assert(Thread.isMainThread)
        let viewController = UIHostingController(
            rootView: NewKeyInvitationView(invitation: invitation)
                .environmentObject(Store.shared)
        )
        self.requestPresentationStyle(.expanded)
        self.showDetailViewController(viewController, sender: self)
    }
    
    private func didCreateKey(url: URL, invitation: NewKey.Invitation) {
        self.requestPresentationStyle(.compact)
        self.navigationController?.popToRootViewController(animated: true)
        Task {
            do {
                try await insertMessage(for: invitation)
                let _ = try? await Store.shared.newKeyInvitations.delete(url)
            } catch {
                log("⚠️ Unable to insert message for invitation \(invitation.key.id)")
            }
        }
    }
    
    private func insertMessage(for invitation: NewKey.Invitation) async throws {
        
        guard let conversation = activeConversation else { fatalError("Expected a conversation") }
        
        let lockURL = LockURL.newKey(invitation)
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "url", value: lockURL.rawValue.absoluteString)
        ]
        
        let layout = MSMessageTemplateLayout()
        layout.mediaFileURL = AssetExtractor.shared.url(for: invitation.key.permission.type)
        layout.caption = "Shared \(invitation.key.permission.type.localizedText) key"
        
        let message = MSMessage(session: activeConversation?.selectedMessage?.session ?? MSSession())
        message.url = components.url!
        message.layout = layout
        
        // Add the message to the conversation.
        try await conversation.insert(message)
    }
}

private extension MessagesViewController {
    
    func loadChildViewController(_ viewController: UIViewController) {
        assert(Thread.isMainThread)
        
        // remove previous
        for childViewController in self.children {
            childViewController.viewIfLoaded?.removeFromSuperview()
            childViewController.removeFromParent()
        }
        
        viewController.loadViewIfNeeded()
        viewController.view.layoutIfNeeded()
        
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        
        guard let childView = viewController.view else {
            assertionFailure()
            return
        }
        
        childView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childView.leftAnchor.constraint(equalTo: view.leftAnchor),
            childView.rightAnchor.constraint(equalTo: view.rightAnchor),
            childView.topAnchor.constraint(equalTo: view.topAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - Extensions

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
