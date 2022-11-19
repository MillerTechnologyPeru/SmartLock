//
//  MessagesAppView.swift
//  LockMessage
//
//  Created by Alsey Coleman Miller on 9/27/22.
//

import Foundation
import UIKit
import SwiftUI
import Messages

struct MessagesAppView <Content: View> : UIViewControllerRepresentable {
    
    let content: Content
    
    @State
    var presentationStyle: MSMessagesAppPresentationStyle = .compact
    
    init(content: () -> (Content)) {
        self.content = content()
    }
    
    func makeUIViewController(context: Context) -> UIViewControllerType {
        let viewController = UIViewControllerType()
        let childViewController = UIHostingController(rootView: content)
        viewController.loadChildViewController(childViewController)
        return viewController
    }
    
    func updateUIViewController(_ viewController: UIViewControllerType, context: Context) {
        // request presentation style
        if viewController.presentationStyle != presentationStyle {
            viewController.requestPresentationStyle(presentationStyle)
        }
        
        // set root view
        (viewController.children[0] as! UIHostingController<Content>).rootView = self.content
    }
}

extension MessagesAppView {
    
    final class UIViewControllerType: MSMessagesAppViewController {
        
        var log: ((String) -> ())? = { NSLog($0) }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            log?("✉️ Loaded \(MessagesAppView.self)")
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
        }
        
        // MARK: - Conversation Handling
        
        override func willBecomeActive(with conversation: MSConversation) {
            log?("✉️ Will become active")
            
            guard let selectedMessage = conversation.selectedMessage else {
                return
            }
            log?("✉️ Selected message \(selectedMessage.url?.absoluteString ?? selectedMessage.description)")
            
        }
        
        override func didResignActive(with conversation: MSConversation) {
            log?("✉️ Did resign active")
        }
       
        override func didReceive(_ message: MSMessage, conversation: MSConversation) {
            // Use this method to trigger UI updates in response to the message.
            log?("✉️ Did recieve \(message)")
        }
        
        override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
            // Called when the user taps the send button.
            log?("✉️ Did recieve \(message)")
        }
        
        override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
            // Called when the user deletes the message without sending it.
            // Use this to clean up state related to the deleted message.
            log?("✉️ Did cancel sending \(message)")
        }
        
        override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
            // Called before the extension transitions to a new presentation style.
            // Use this method to prepare for the change in presentation style.
            log?("✉️ Will transition to \(presentationStyle.debugDescription)")
            
        }
        
        override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
            // Called after the extension transitions to a new presentation style.
            // Use this method to finalize any behaviors associated with the change in presentation style.
            log?("✉️ Did transition to \(presentationStyle.debugDescription)")
            
        }
    }
}
