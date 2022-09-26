//
//  AsyncFetchRequest.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/22/22.
//

import Foundation
import SwiftUI

@propertyWrapper
@MainActor
public struct AsyncFetchRequest <DataSource: AsyncFetchDataSource> {
    
    internal let dataSource: DataSource
    
    internal let configuration: DataSource.Configuration
    
    public init(
        dataSource: DataSource,
        configuration: DataSource.Configuration
    ) {
        self.dataSource = dataSource
        self.configuration = configuration
    }
    
    public var wrappedValue: AsyncFetchedResults<DataSource> {
        return .init(
            dataSource: dataSource,
            configuration: configuration
        )
    }
}

public extension AsyncFetchRequest where DataSource.Configuration == Void {
    
    init(
        dataSource: DataSource
    ) {
        self.init(
            dataSource: dataSource,
            configuration: ()
        )
    }
}

public protocol AsyncFetchDataSource {
    
    associatedtype ID: Hashable
    
    associatedtype Success
    
    associatedtype Failure: Error
    
    associatedtype Configuration
    
    /// Provide the cached result if value has been fetched.
    func cachedValue(for id: ID) -> Success?
    
    /// Provide sorted and filtered results.
    func fetch(configuration: Configuration) -> [ID]
    
    /// Asyncronously load the specified item.
    func load(_ id: ID) async -> Result<Success, Failure>
}

extension AsyncFetchRequest: DynamicProperty {
    
    public mutating func update() {
        print(#function)
    }
}

@MainActor
public struct AsyncFetchedResults <DataSource: AsyncFetchDataSource> {
    
    //@ObservedObject
    internal var dataSource: DataSource
    
    internal var configuration: DataSource.Configuration
    
    @State
    internal var results = [DataSource.ID]()
    
    @State
    internal var tasks = [DataSource.ID: Task<Void, Never>]()
    
    @State
    internal var errors = [DataSource.ID: DataSource.Failure]()
    
    public init(
        dataSource: DataSource,
        configuration: DataSource.Configuration
    ) {
        self.dataSource = dataSource
        self.configuration = configuration
    }
}

public extension AsyncFetchedResults {
    
    func reset() {
        results.removeAll(keepingCapacity: true)
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
    }
    
    func reload() {
        reset()
        results = dataSource.fetch(configuration: configuration)
    }
}

public extension AsyncFetchedResults {
    
    enum Element {
        case loading(DataSource.ID)
        case success(DataSource.ID, DataSource.Success)
        case failure(DataSource.ID, DataSource.Failure)
    }
}

extension AsyncFetchedResults.Element: Identifiable {
    
    public var id: DataSource.ID {
        switch self {
        case let .loading(id):
            return id
        case let .success(id, _):
            return id
        case let .failure(id, _):
            return id
        }
    }
}

private extension AsyncFetchedResults.Element {
    
    init(
        id: DataSource.ID,
        result: Result<DataSource.Success, DataSource.Failure>?
    ) {
        guard let result = result else {
            self = .loading(id)
            return
        }
        switch result {
        case .success(let success):
            self = .success(id, success)
        case .failure(let failure):
            self = .failure(id, failure)
        }
    }
}

extension AsyncFetchedResults: RandomAccessCollection {
    
    public var count: Int {
        // fetch
        results = dataSource.fetch(configuration: configuration)
        return results.count
    }
    
    public var isEmpty: Bool {
        count == 0
    }
    
    public var startIndex: Int {
        results.startIndex
    }
    
    public var endIndex: Int {
        results.endIndex
    }
    
    public func index(after index: Int) -> Int {
        results.index(after: index)
    }
    
    public subscript(index: Int) -> Element {
        let id = results[index]
        // return cached value
        if let cachedValue = dataSource.cachedValue(for: id) {
            return .success(id, cachedValue)
        } else {
            // async load
            if tasks[id] == nil {
                tasks[id] = Task {
                    // load
                    let result = await dataSource.load(id)
                    // save error
                    switch result {
                    case .success:
                        break // observer should update
                    case .failure(let failure):
                        self.errors[id] = failure
                    }
                    // remove task so it can be reloaded if not cached
                    self.tasks[id] = nil
                }
            }
            if let error = errors[id] {
                return .failure(id, error)
            } else {
                assert(tasks[id] != nil)
                return .loading(id)
            }
        }
    }
}
