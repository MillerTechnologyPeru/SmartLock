//
//  TestIntent.swift
//  LockIntents
//
//  Created by Alsey Coleman Miller on 9/23/22.
//

import AppIntents

#if DEBUG0
struct TestIntents: AppIntent {
    
    static var title: LocalizedStringResource = "TestIntents"
    
    @Parameter(title: "Duration", default: 2)
    var duration: TimeInterval
    
    func perform() async throws -> some IntentResult {
        try await Task.sleep(for: .seconds(duration))
        let entity = { TestLockEntity(id: UUID(), buildVersion: 1, version: "1.0.0") }
        return .result(value: [entity(), entity(), entity()])
    }
}

struct TestIntents2: AppIntent {
    
    static var title: LocalizedStringResource = "TestIntents 2"
    
    @Parameter(title: "Lock")
    var lock: TestLockEntity
    
    func perform() async throws -> some IntentResult {
        try await Task.sleep(for: .seconds(1))
        let entity = { TestLockEntity(id: UUID(), buildVersion: 1, version: "1.0.0") }
        return .result(value: entity().id.description)
    }
}


/// Lock Intent Entity
struct TestLockEntity: AppEntity, Identifiable, Sendable {
    
    let id: UUID
    
    /// Firmware build number
    var buildVersion: UInt64
    
    /// Firmware version
    var version: String
    
    /// Device state
    //var status: CoreLock.LockStatus
    
    /// Supported lock actions
    //var unlockActions: Set<CoreLock.UnlockAction>
}

extension TestLockEntity {
    
    static var defaultQuery = TestLockQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Lock"
    }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "Lock",
            subtitle: "UUID \(id.description) v\(version.description)",
            image: .init(systemName: "lock.fill")
        )
    }
    
    func suggestedEntities() async throws -> [TestLockEntity] {
        let entity = { TestLockEntity(id: UUID(), buildVersion: 1, version: "1.0.0") }
        return [entity(), entity(), entity()]
    }
}

struct TestLockQuery: EntityQuery {
    
    func entities(for identifiers: [UUID]) async throws -> [TestLockEntity] {
        return identifiers.map {
            TestLockEntity(id: $0, buildVersion: 1, version: "1")
        }
    }
}

#endif
