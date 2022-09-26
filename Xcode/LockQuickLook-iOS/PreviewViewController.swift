//
//  PreviewViewController.swift
//  LockQuickLook
//
//  Created by Alsey Coleman Miller on 9/26/22.
//

import Foundation
import UIKit
import QuickLook
import LockKit
import SwiftUI

final class PreviewViewController: UIViewController, QLPreviewingController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        assert(Thread.isMainThread)
        // set global appearance
        UIView.configureLockAppearance()
        // log
        log("👁‍🗨 Loaded \(PreviewViewController.self)")
    }
    
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?) async throws {
        log("👁‍🗨 Prepare preview for searchable item \(identifier) \(queryString ?? "")")
        
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
        let viewController = UIHostingController(
            rootView: NewKeyInvitationView(invitation: invitation)
                .environmentObject(Store.shared)
        )
        loadChildViewController(viewController)
    }
    
    func loadChildViewController(_ viewController: UIViewController) {
        assert(Thread.isMainThread)
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
