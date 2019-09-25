//
//  PreviewViewController.swift
//  QuickLook
//
//  Created by Alsey Coleman Miller on 9/24/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import QuickLook
import CoreLock
import LockKit

final class PreviewViewController: UIViewController, QLPreviewingController {
    
    private static let initialize: Void = {
        Log.shared = .quickLook
        log("👁‍🗨 Loading \(PreviewViewController.self)")
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup logging
        _ = type(of: self).initialize
        
    }
    
    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        // Perform any setup necessary in order to prepare the view.
        log("👁‍🗨 Prepare preview for searchable item \(identifier) \(queryString ?? "")")
        
        //FileManager.Lock.shared.applicationData
        
        handler(nil)
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        log("👁‍🗨 Prepare preview for \(url)")
        
        guard url.pathExtension == "ekey" else {
            log("⚠️ Not eKey file: \(url)")
            handler(CocoaError(.fileReadInvalidFileName))
            return
        }
        
        DispatchQueue.app.async {
            
            let decoder = JSONDecoder()
            
            // load eKey file
            let invitation: NewKey.Invitation
            do {
                let data = try Data(contentsOf: url)
                invitation = try decoder.decode(NewKey.Invitation.self, from: data)
            } catch {
                log("⚠️ Unable to load eKey file \(url). \(error)")
                DispatchQueue.main.async { handler(error) }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.loadNewKey(invitation)
                handler(nil)
            }
        }
    }
}

private extension PreviewViewController {
    
    func loadNewKey(_ invitation: NewKey.Invitation) {
        
        let viewController = NewKeyRecieveViewController.fromStoryboard(with: invitation)
        
        viewController.loadViewIfNeeded()
        viewController.view.layoutIfNeeded()
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        
        guard let newKeyView = viewController.view else {
            assertionFailure()
            return
        }
        
        newKeyView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newKeyView.leftAnchor.constraint(equalTo: view.leftAnchor),
            newKeyView.rightAnchor.constraint(equalTo: view.rightAnchor),
            newKeyView.topAnchor.constraint(equalTo: view.topAnchor),
            newKeyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - Logging

extension Log {
    
    static var quickLook: Log {
        struct Cache {
            static let log: Log = {
                do { return try Log.Store.lockAppGroup.create(date: Date(), bundle: .init(for: PreviewViewController.self)) }
                catch { assertionFailure("Could not create log file: \(error)"); return .appCache }
            }()
        }
        return Cache.log
    }
}
