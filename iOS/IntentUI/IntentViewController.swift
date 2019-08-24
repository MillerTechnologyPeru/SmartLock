//
//  IntentViewController.swift
//  IntentUI
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import UIKit
import IntentsUI
import CoreBluetooth
import CoreLock
import LockKit

// As an example, this extension's Info.plist has been configured to handle interactions for INSendMessageIntent.
// You will want to replace this or add other intents as appropriate.
// The intents whose interactions you wish to handle must be declared in the extension's Info.plist.

// You can test this example integration by saying things to Siri like:
// "Send a message using <myApp>"

final class IntentViewController: UIViewController, INUIHostedViewControlling {
    
    // MARK: - IB Outlets
    
    @IBOutlet private(set) weak var lockImageView: UIImageView!
    @IBOutlet private(set) weak var lockTitleLabel: UILabel!
    @IBOutlet private(set) weak var lockDetailLabel: UILabel!
    @IBOutlet private(set) weak var activityViewController: UIActivityIndicatorView!
    
    // MARK: - Loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let _ = IntentViewController.didLaunch
        
        log("🎙 Loaded \(IntentViewController.self)")
    }
        
    // MARK: - INUIHostedViewControlling
    
    // Prepare your view controller for the interaction to handle.
    func configureView(for parameters: Set<INParameter>,
                       of interaction: INInteraction,
                       interactiveBehavior: INUIInteractiveBehavior,
                       context: INUIHostedViewContext,
                       completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {
        
        assert(isViewLoaded)
        
        guard let intent = interaction.intent as? UnlockIntent,
            let lockIdentifierString = intent.lock?.identifier,
            let lockIdentifier = UUID(uuidString: lockIdentifierString),
            let lockCache = Store.shared[lock: lockIdentifier] else {
            completion(false, [], .zero)
            return
        }
        
        log("🎙 Show UI for lock \(lockCache.name) \(lockCache.key.permission.type) \(lockIdentifier)")
        
        let desiredSize: CGSize
        
        switch interaction.intentHandlingStatus {
        case .ready:
            desiredSize = configureView(for: lockCache)
        case .inProgress:
            desiredSize = configureView(for: lockCache, inProgress: true)
        case .success:
            desiredSize = configureView(for: lockCache)
        case .failure:
            desiredSize = .zero
        case .deferredToApplication:
            desiredSize = .zero
        case .userConfirmationRequired:
            desiredSize = .zero
        case .unspecified:
            desiredSize = configureView(for: lockCache)
        @unknown default:
            desiredSize = configureView(for: lockCache)
        }
        
        // Do configuration here, including preparing views and calculating a desired size for presentation.
        completion(desiredSize != .zero, parameters, desiredSize)
    }
    
    func configureView(for lock: LockCache, inProgress: Bool = false) -> CGSize {
        
        let width = self.extensionContext?.hostedViewMaximumAllowedSize.width ?? 320
        let desiredSize = CGSize(width: width, height: 76)
        
        self.lockImageView.image = UIImage(permission: lock.key.permission)
        self.lockTitleLabel.text = lock.name
        self.lockDetailLabel.text = lock.key.permission.localizedText
        self.activityViewController.isHidden = inProgress == false
        if inProgress, self.activityViewController.isAnimating == false {
            if self.activityViewController.isAnimating == false {
                self.activityViewController.startAnimating()
            }
        } else {
            self.activityViewController.stopAnimating()
        }
        
        return desiredSize
    }
}

private extension IntentViewController {
    
    static let didLaunch: Void = {
        
        // configure logging
        Log.shared = .intentUI
        
        // setup Logging
        log("🎙 Launching Intent UI")
        LockManager.shared.log = { log("🔒 LockManager: " + $0) }
        BeaconController.shared.log = { log("📶 \(BeaconController.self): " + $0) }
    }()
}

// MARK: - Logging

extension Log {
    
    static var intentUI: Log {
        struct Cache {
            static let log: Log = {
                do { return try Log.Store.lockAppGroup.create(date: Date(), bundle: .init(for: IntentViewController.self)) }
                catch { assertionFailure("Could not create log file: \(error)"); return .appCache }
            }()
        }
        return Cache.log
    }
}
