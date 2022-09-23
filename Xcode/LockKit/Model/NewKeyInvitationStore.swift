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
    
    @Published
    public private(set) var cache = Cache()
    
    internal lazy var fileManager = FileManager()
    
    public static let shared = NewKeyInvitationStore()
    
    private init() { }
    
    @discardableResult
    public func save(
        _ invitation: NewKey.Invitation,
        fileName: String? = nil
    ) async throws -> URL {
        let documentsURL = try self.documentsURL
        let fileName = fileName ?? "newKey-\(invitation.key.id).ekey"
        let fileURL = documentsURL.appendingPathComponent(fileName)
        let encoder = JSONEncoder()
        let writeTask = Task {
            let data = try encoder.encode(invitation)
            try data.write(to: fileURL, options: [.atomic])
        }
        // wait for task
        try await writeTask.value
        await self.cache(invitation, url: fileURL)
        return fileURL
    }
    /*
    @discardableResult
    public func fetchAll() async throws -> Cache {
        let documentsURL = try self.documentsURL
        let files = try fileManager.contentsOfDirectory(atPath: documentsURL.path)
        let keyFiles = files.filter { $0.hasSuffix(".ekey") }
        
        // attempt to read concurrently
        let oldValue = await MainActor.run { self.cache }
        let newValue = await withTaskGroup(of: (URL, Result<NewKey.Invitation, Swift.Error>).self, returning: Cache.self) { taskGroup in
            for path in keyFiles {
                let url = URL(fileURLWithPath: path)
                taskGroup.addTask {
                    do {
                        let decoder = JSONDecoder()
                        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
                        let value = try decoder.decode(NewKey.Invitation.self, from: data)
                        // update UI incrementally
                        await self.cache(value, url: url)
                        return (url, .success(value))
                    }
                    catch {
                        log("⚠️ Unable to read \(url.lastPathComponent). \(error.localizedDescription)")
                        return (url, .failure(error))
                    }
                }
            }
            
            // build result serially
            var newValue = Cache()
            newValue.reserveCapacity(oldValue.count + 2)
            for await value in taskGroup {
                switch value {
                case let .success(newKey):
                    newValue[newKey]
                case let .failure(error):
                    // decrement count
                    break
                }
            }
            return newValue
        }
        // replace everything
        await MainActor.run {
            self.cache = newValue
        }
        return newValue
    }
    */
    internal var documentsURL: URL {
        get throws {
            guard let url = fileManager.documentsURL else {
                throw CocoaError(.fileNoSuchFile)
            }
            return url
        }
    }
    
    @MainActor
    private func cache(_ value: NewKey.Invitation, url: URL) async {
        self.cache[url] = value
    }
}
