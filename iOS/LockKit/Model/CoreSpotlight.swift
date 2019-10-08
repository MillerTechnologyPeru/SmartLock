//
//  CoreSpotlight.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/21/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreSpotlight
import MobileCoreServices
import class UIKit.UIImage

/// Managed the Spotlight index.
@available(iOS 9.0, *)
public final class SpotlightController {
    
    // MARK: - Initialization
    
    public static let shared = SpotlightController(index: .default())
    
    public init(index: CSSearchableIndex) {
        self.index = index
    }
    
    // MARK: - Properties
    
    internal let index: CSSearchableIndex
    
    public var log: ((String) -> ())?
    
    /// Returns a Boolean value that indicates whether indexing is available on the current device.
    public static var isSupported: Bool {
        return CSSearchableIndex.isIndexingAvailable()
    }
    
    // MARK: - Methods
    
    public func reindexAll(locks: [UUID: LockCache], completion: ((Error?) -> ())? = nil) {
        
        let searchableItems = locks
            .lazy
            .map { SearchableLock(identifier: $0.key, cache: $0.value) }
            .map { $0.searchableItem() }
        
        index.deleteSearchableItems(withDomainIdentifiers: [SearchableLock.searchDomain]) { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.log?("⚠️ Error deleting: \(error.localizedDescription)")
                completion?(error)
                return
            }
            self.log?("Deleted old items")
            self.index.indexSearchableItems(Array(searchableItems)) { [weak self] (error) in
                guard let self = self else { return }
                if let error = error {
                    self.log?("⚠️ Error: \(error.localizedDescription)")
                    completion?(error)
                    return
                }
                self.log?("Indexed items")
                completion?(nil)
            }
        }
    }
    
    /// Reindex the searchable items associated with the specified identifiers.
    public func reindex(_ identifiers: [String],
                        for locks: [UUID: LockCache],
                        completion: ((Error?) -> ())? = nil) {
        
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
                    let item = SearchableLock(identifier: lock, cache: cache).searchableItem()
                    searchableItems.append(item)
                } else {
                    deletedItems.insert(searchIdentifier)
                }
            }
        }
        
        index.deleteSearchableItems(withIdentifiers: Array(deletedItems)) { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.log?("⚠️ Error deleting: \(error.localizedDescription)")
                completion?(error)
                return
            }
            self.log?("Deleted \(deletedItems.count) old items")
            self.index.indexSearchableItems(searchableItems) { [weak self] (error) in
                guard let self = self else { return }
                if let error = error {
                    self.log?("⚠️ Error indexing: \(error.localizedDescription)")
                    completion?(error)
                    return
                }
                self.log?("Indexed \(searchableItems.count) items")
                completion?(nil)
            }
        }
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
    
    static var itemContentType: String { return kUTTypeText as String }
    
    func searchableItem() -> CSSearchableItem {
        
        let attributeSet = searchableAttributeSet()
        
        return CSSearchableItem(uniqueIdentifier: searchIdentifier,
                                domainIdentifier: type(of: self).searchDomain,
                                attributeSet: attributeSet)
    }
}

public struct SearchableLock: Equatable {
    
    public let identifier: UUID
    
    public let cache: LockCache
}

extension SearchableLock: CoreSpotlightSearchable {
    
    public static var activityDataType: AppActivity.DataType { return .lock }
    
    public static var searchDomain: String { return "com.colemancda.Lock.LockCache" }
    
    public var searchIdentifier: String {
        return type(of: self).searchIdentifier(for: identifier)
    }
    
    public static func searchIdentifier(for lock: UUID) -> String {
        return AppActivity.ViewData.lock(lock).rawValue
    }
    
    public var appActivity: AppActivity.ViewData {
        return .lock(identifier)
    }
    
    public func searchableAttributeSet() -> CSSearchableItemAttributeSet {
        
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: Swift.type(of: self).itemContentType)
        
        let permission = cache.key.permission
        let permissionText = permission.localizedText
        
        attributeSet.displayName = cache.name
        attributeSet.contentDescription = permissionText
        attributeSet.version = cache.information.version.description
        attributeSet.thumbnailURL = AssetExtractor.shared.url(for: permission.type.image)
        
        return attributeSet
    }
}
