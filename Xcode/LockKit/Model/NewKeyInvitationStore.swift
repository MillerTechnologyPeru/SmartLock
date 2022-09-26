//
//  NewKeyInvitationStore.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/21/22.
//

import Foundation
import CoreLock

/// Store for managing invitation files that you created.
public final class NewKeyInvitationStore: ObservableObject {
    
    public typealias Cache = [URL: NewKey.Invitation]
    
    // MARK: - Properties
    
    @Published
    public private(set) var cache = Cache()
    
    internal let fileManager = FileManager()
    
    internal let encoder = JSONEncoder()
    
    internal let decoder = JSONDecoder()
    
    // MARK: - Initialization
    
    public static let shared = NewKeyInvitationStore()
    
    private init() { }
    
    // MARK: - Methods
    
    public func fetchDocuments() throws -> [URL] {
        return try fileManager
            .contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [
                    .creationDateKey
                ],
                options: [.skipsHiddenFiles]
            )
            .lazy
            .filter { $0.lastPathComponent.hasSuffix(".ekey") }
            .map { (url: $0, date: (try? self.fileManager.attributesOfItem(atPath: $0.path)[FileAttributeKey.creationDate] as? Date) ?? Date()) }
            .sorted  { $0.date < $1.date }
            .map { $0.url }
    }
    
    @discardableResult
    public func delete(_ url: URL) async throws -> Bool {
        guard fileManager.fileExists(atPath: url.path) else {
            return false
        }
        try fileManager.removeItem(at: url)
        await removeCached(url)
        return true
    }
    
    @discardableResult
    public func save(
        _ invitation: NewKey.Invitation,
        fileName: String? = nil
    ) async throws -> URL {
        let documentsURL = try self.documentsURL
        let fileName = fileName ?? "newKey-\(invitation.key.id).ekey"
        let fileURL = documentsURL.appendingPathComponent(fileName)
        let writeTask = Task {
            let data = try encoder.encode(invitation)
            try data.write(to: fileURL, options: [.atomic])
        }
        // wait for task
        try await writeTask.value
        await self.cache(invitation, url: fileURL)
        return fileURL
    }
    
    public func load(_ url: URL) async throws -> NewKey.Invitation {
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let invitation = try decoder.decode(NewKey.Invitation.self, from: data)
        await cache(invitation, url: url)
        return invitation
    }
    
    internal var documentsURL: URL {
        get throws {
            guard let url = fileManager.documentsURL else {
                throw CocoaError(.fileNoSuchFile)
            }
            return url
        }
    }
    
    @MainActor
    private func cache(_ value: NewKey.Invitation, url: URL) {
        self.cache[url] = value
    }
    
    @MainActor
    private func removeCached(_ url: URL) {
        self.cache.removeValue(forKey: url)
    }
}
