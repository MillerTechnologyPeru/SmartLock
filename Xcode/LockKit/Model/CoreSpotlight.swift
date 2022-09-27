//
//  CoreSpotlight.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

#if canImport(CoreSpotlight)
import Foundation
import CoreSpotlight
import CoreLock

#if canImport(MobileCoreServices)
import MobileCoreServices
#endif

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Managed the Spotlight index.
public final class SpotlightController {
    
    // MARK: - Initialization
    
    public static let shared = SpotlightController(index: .default())
    
    private init(index: CSSearchableIndex) {
        self.index = index
    }
    
    // MARK: - Properties
    
    internal let index: CSSearchableIndex
    
    public var log: ((String) -> ())? = { LockKit.log("🔦 \(SpotlightController.self): " + $0) }
    
    /// Returns a Boolean value that indicates whether indexing is available on the current device.
    public static var isSupported: Bool {
        return CSSearchableIndex.isIndexingAvailable()
    }
    
    // MARK: - Methods
    
    public func reindexAll(
        locks: [UUID: LockCache]
    ) async throws {
        
        let searchableItems = locks
            .lazy
            .map { SearchableLock(id: $0.key, cache: $0.value) }
            .map { $0.searchableItem() }
        
        try await index.deleteSearchableItems(withDomainIdentifiers: [SearchableLock.searchDomain])
        log?("Deleted all old items")
        try await index.indexSearchableItems(Array(searchableItems))
        log?("Indexed \(searchableItems.count) items")
    }
    
    /// Reindex the searchable items associated with the specified identifiers.
    public func reindex(
        _ identifiers: [String],
        for locks: [UUID: LockCache]
    ) async throws {
        
        var deletedItems = Set<String>()
        var searchableItems = [CSSearchableItem]()
        searchableItems.reserveCapacity(identifiers.count)
        
        for identifier in identifiers {
            
            guard let viewData = AppActivity.ViewData(rawValue: identifier) else {
                log?("⚠️ Invalid index \(identifier)")
                continue
            }
            
            switch viewData {
            case let .lock(lock):
                let searchIdentifier = SearchableLock.searchIdentifier(for: lock)
                if let cache = locks[lock] {
                    let item = SearchableLock(id: lock, cache: cache).searchableItem()
                    searchableItems.append(item)
                } else {
                    deletedItems.insert(searchIdentifier)
                }
            }
        }
        
        // delete and reindex certain items
        try await index.deleteSearchableItems(withIdentifiers: Array(deletedItems))
        log?("Deleted \(deletedItems.count) old items")
        try await index.indexSearchableItems(searchableItems)
        log?("Indexed \(searchableItems.count) items")
        
    }
}

// MARK: - Supporting Types

public protocol CoreSpotlightSearchable: AppActivityData {
    
    static var itemContentType: String { get }
    
    static var searchDomain: String { get }
    
    var searchIdentifier: String { get }
    
    func searchableItem() -> CSSearchableItem
    
    func searchableAttributeSet() -> CSSearchableItemAttributeSet
}

public extension CoreSpotlightSearchable {
    
    static var itemContentType: String { return UTType.text.identifier }
    
    func searchableItem() -> CSSearchableItem {
        let attributeSet = searchableAttributeSet()
        return CSSearchableItem(
            uniqueIdentifier: searchIdentifier,
            domainIdentifier: type(of: self).searchDomain,
            attributeSet: attributeSet
        )
    }
}

public struct SearchableLock: Equatable {
    
    public let id: UUID
    
    public let cache: LockCache
}

extension SearchableLock: CoreSpotlightSearchable {
    
    public static var activityDataType: AppActivity.DataType { return .lock }
    
    public static var searchDomain: String { return "com.colemancda.Lock.Spotlight.Lock" }
    
    public var searchIdentifier: String {
        return type(of: self).searchIdentifier(for: id)
    }
    
    public static func searchIdentifier(for lock: UUID) -> String {
        return AppActivity.ViewData.lock(lock).rawValue
    }
    
    public var appActivity: AppActivity.ViewData {
        return .lock(id)
    }
    
    public func searchableAttributeSet() -> CSSearchableItemAttributeSet {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: Swift.type(of: self).itemContentType)
        let permission = cache.key.permission
        let permissionText = permission.localizedText
        attributeSet.displayName = cache.name
        attributeSet.contentDescription = permissionText
        attributeSet.version = cache.information.version.description
        if Thread.isMainThread {
            attributeSet.thumbnailURL = AssetExtractor.shared.url(for: permission.type)
        } else {
            DispatchQueue.main.sync {
                attributeSet.thumbnailURL = AssetExtractor.shared.url(for: permission.type)
            }
        }
        return attributeSet
    }
}
#endif
