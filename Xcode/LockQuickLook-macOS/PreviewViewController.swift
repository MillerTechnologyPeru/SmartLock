//
//  PreviewViewController.swift
//  LockQuickLook-macOS
//
//  Created by Alsey Coleman Miller on 9/26/22.
//

import Cocoa
import Quartz
import SwiftUI
import LockKit

final class PreviewViewController: NSViewController, QLPreviewingController {
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view.
        assert(Thread.isMainThread)
        // log
        log("👁‍🗨 Loaded \(PreviewViewController.self)")
    }
    
    func preparePreviewOfFile(at url: URL) async throws {
        
        log("👁‍🗨 Prepare preview for \(url)")
        
        guard url.pathExtension == "ekey" else {
            log("⚠️ Not eKey file: \(url)")
            throw CocoaError(.fileReadInvalidFileName)
        }
        
        let decodeTask = Task {
            let decoder = JSONDecoder()
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            let invitation = try decoder.decode(NewKey.Invitation.self, from: data)
            return invitation
        }
        
        // load store
        let _ = Store.shared
        let invitation = try await decodeTask.value
        
        // update UI
        await MainActor.run {
            loadNewKey(invitation)
        }
    }
}

@MainActor
private extension PreviewViewController {
    
    func loadNewKey(_ invitation: NewKey.Invitation) {
        assert(Thread.isMainThread)
        let viewController = NSHostingController(
            rootView: NewKeyInvitationView(invitation: invitation)
                .environmentObject(Store.shared)
        )
        loadChildViewController(viewController)
    }
    
    func loadChildViewController(_ viewController: NSViewController) {
        assert(Thread.isMainThread)
        viewController.loadView()
        viewController.view.layout()
        addChild(viewController)
        view.addSubview(viewController.view)
        //viewController .didMove(toParent: self)
        let childView = viewController.view
        childView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            childView.leftAnchor.constraint(equalTo: view.leftAnchor),
            childView.rightAnchor.constraint(equalTo: view.rightAnchor),
            childView.topAnchor.constraint(equalTo: view.topAnchor),
            childView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

