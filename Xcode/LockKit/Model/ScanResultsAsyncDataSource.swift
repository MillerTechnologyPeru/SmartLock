//
//  ScanResultsAsyncFetchRequest.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/25/22.
//

import Foundation
import Combine
import GATT
import CoreLock

@MainActor
public final class ScanResultsAsyncDataSource: AsyncFetchDataSource {
    
    public typealias Configuration = Void
    
    public let store: Store
    
    public let objectWillChange: ObservableObjectPublisher
    
    public init(store: Store = .shared) {
        self.store = store
        self.objectWillChange = store.objectWillChange
    }
    
    /// Provide the cached result if value has been fetched.
    public func cachedValue(for id: NativePeripheral) -> LockInformation? {
        return store.lockInformation[id]
    }
    
    /// Provide sorted and filtered results.
    public func fetch(configuration: Configuration = ()) -> [NativePeripheral] {
        return store.peripherals.keys
            .lazy
            .sorted(by: { store.lockInformation[$0]?.id.description ?? "" > store.lockInformation[$1]?.id.description ?? ""  })
            .sorted(by: {
                store.applicationData.locks[store.lockInformation[$0]?.id ?? UUID()]?.key.created ?? .distantFuture > store.applicationData.locks[store.lockInformation[$1]?.id ?? UUID()]?.key.created ?? .distantFuture })
            .sorted(by: { $0.description < $1.description })
    }
    
    /// Asyncronously load the specified item.
    public nonisolated func load(_ id: NativePeripheral) async -> Result<LockInformation, Error> {
        do {
            let value = try await store.readInformation(for: id)
            return .success(value)
        } catch {
            return .failure(error)
        }
    }
}
