//
//  IndexRequestHandler.swift
//  Spotlight
//
//  Created by Alsey Coleman Miller on 9/25/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreSpotlight
import CoreLock
import LockKit

final class IndexRequestHandler: CSIndexExtensionRequestHandler {

    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexAllSearchableItemsWithAcknowledgementHandler acknowledgementHandler: @escaping () -> Void) {
        // Reindex all data with the provided index
        _ = type(of: self).initialize
        log("🔦 Reindex all searchable items")
        let spotlight = controller(for: searchableIndex)
        let locks = FileManager.Lock.shared.applicationData?.locks ?? [:]
        spotlight.reindexAll(locks: locks) { _ in
            acknowledgementHandler()
        }
    }
    
    override func searchableIndex(_ searchableIndex: CSSearchableIndex, reindexSearchableItemsWithIdentifiers identifiers: [String], acknowledgementHandler: @escaping () -> Void) {
        // Reindex any items with the given identifiers and the provided index
        _ = type(of: self).initialize
        log("🔦 Reindex \(identifiers.count) searchable items")
        let spotlight = controller(for: searchableIndex)
        let locks = FileManager.Lock.shared.applicationData?.locks ?? [:]
        spotlight.reindex(identifiers, for: locks) { _ in
            acknowledgementHandler()
        }
    }
    
    override func data(for searchableIndex: CSSearchableIndex, itemIdentifier: String, typeIdentifier: String) throws -> Data {
        // Replace with Data representation of requested type from item identifier
        _ = type(of: self).initialize
        log("🔦 Data for \(itemIdentifier) \(typeIdentifier)")
        assertionFailure()
        return Data()
    }
    
    override func fileURL(for searchableIndex: CSSearchableIndex, itemIdentifier: String, typeIdentifier: String, inPlace: Bool) throws -> URL {
        // Replace with to return file url based on requested type from item identifier
        _ = type(of: self).initialize
        log("🔦 File URL for \(itemIdentifier) \(typeIdentifier)")
        assertionFailure()
        return URL(string:"file://")!
    }
}

private extension IndexRequestHandler {
    
    static let initialize: Void = {
        Log.shared = .spotlight
        log("🖼 Loading \(IndexRequestHandler.self)")
    }()
    
    func controller(for index: CSSearchableIndex) -> SpotlightController {
        _ = type(of: self).initialize
        let controller = SpotlightController(index: index)
        controller.log = { log("🔦 \(SpotlightController.self): " + $0) }
        return controller
    }
}

// MARK: - Logging

extension Log {
    
    static var spotlight: Log {
        struct Cache {
            static let log: Log = {
                do { return try Log.Store.lockAppGroup.create(date: Date(), bundle: .init(for: IndexRequestHandler.self)) }
                catch { assertionFailure("Could not create log file: \(error)"); return .appCache }
            }()
        }
        return Cache.log
    }
}
