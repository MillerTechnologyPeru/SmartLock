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
    
    public static let shared = SpotlightController()
    
    private init(index: CSSearchableIndex = .default()) {
        self.index = index
    }
    
    // MARK: - Properties
    
    private let index: CSSearchableIndex
    
    public var log: ((String) -> ())?
    
    // MARK: - Methods
    
    public func update(locks: [UUID: LockCache]) {
        
        let searchableItems = locks
            .lazy
            .map { SearchableLock(identifier: $0.key, cache: $0.value) }
            .map { $0.searchableItem() }
        
        index.deleteSearchableItems(withDomainIdentifiers: [SearchableLock.searchDomain]) { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.log?("Error: \(error)")
                return
            }
            self.log?("Deleted old locks")
            self.index.indexSearchableItems(Array(searchableItems)) { [weak self] (error) in
                guard let self = self else { return }
                if let error = error {
                    self.log?("Error: \(error)")
                    return
                }
                self.log?("Indexed locks")
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
        return appActivity.rawValue
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
