//
//  Shortcut.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import Intents
import CoreLocation
import CoreLock
#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

#if !targetEnvironment(macCatalyst)
@available(iOS 12.0, watchOS 5.0, *)
public extension INRelevantShortcut {
    
    static func unlock(lock: UUID,
                       cache: LockCache,
                       location: CLLocationCoordinate2D? = nil) -> INRelevantShortcut {
        
        let intent = UnlockIntent(id: lock, cache: cache)
        let relevantShortcut = INRelevantShortcut(shortcut: .intent(intent))
        relevantShortcut.shortcutRole = .action
        relevantShortcut.relevanceProviders = [
            INDailyRoutineRelevanceProvider(situation: .home),
            INDailyRoutineRelevanceProvider(situation: .work)
        ]
        if let location = location {
            let provider = INLocationRelevanceProvider(
                region: CLCircularRegion(
                    center: location,
                    radius: 20.0,
                    identifier: lock.uuidString)
            )
            relevantShortcut.relevanceProviders.append(provider)
        }
        let watchTemplate = INDefaultCardTemplate(title: cache.name)
        let image: UIImage
        #if os(watchOS)
        switch cache.key.permission {
        case .owner: image = #imageLiteral(resourceName: "watchOwner")
        case .admin: image = #imageLiteral(resourceName: "watchAdmin")
        case .anytime: image = #imageLiteral(resourceName: "watchAnytime")
        case .scheduled: image = #imageLiteral(resourceName: "watchScheduled")
        }
        #elseif os(iOS)
        image = UIImage(permission: cache.key.permission)
        #endif
        watchTemplate.image = image.pngData().flatMap { INImage(imageData: $0) }
        watchTemplate.subtitle = cache.key.permission.type.localizedText
        relevantShortcut.watchTemplate = watchTemplate
        return relevantShortcut
    }
}

@available(iOS 12.0, watchOS 5.0, *)
public extension Store {
    
    func setRelevantShortcuts(_ completion: ((Error?) -> Void)? = nil) {

        let relevantShortcuts = locks.map { (lock, cache) in
            INRelevantShortcut.unlock(lock: lock, cache: cache)
        }
        
        let completion = completion ?? { (error) in
            if let error = error {
                log("⚠️ Donating relevant shortcuts failed. \(error.localizedDescription)")
                #if DEBUG
                print(error)
                #endif
            }
        }
        
        INRelevantShortcutStore.default.setRelevantShortcuts(relevantShortcuts, completionHandler: completion)
    }
}
#endif
