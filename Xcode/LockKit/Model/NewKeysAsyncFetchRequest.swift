//
//  NewKeysAsyncFetchRequest.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/25/22.
//

import Foundation
import CoreLock

public extension NewKeyInvitationStore {
    
    struct DataSource: AsyncFetchDataSource {
        
        public typealias Configuration = Void
        
        public let store: NewKeyInvitationStore
        
        public init(store: NewKeyInvitationStore = .shared) {
            self.store = store
        }
        
        /// Provide the cached result if value has been fetched.
        public func cachedValue(for id: URL) -> NewKey.Invitation? {
            return store.cache[id]
        }
        
        /// Provide sorted and filtered results.
        public func fetch(configuration: Configuration = ()) -> [URL] {
            do {
                return try store
                    .fetchDocuments()
                    .sorted { $0.absoluteString < $1.absoluteString }
            }
            catch {
                assertionFailure("Unable to fetch files \(error)")
                return []
            }
        }
        
        /// Asyncronously load the specified item.
        public func load(_ url: URL) async -> Result<NewKey.Invitation, Error> {
            do {
                let value = try await store.load(url)
                return .success(value)
            } catch {
                return .failure(error)
            }
        }
    }
}
