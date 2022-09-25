//
//  LockEventEntity.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/24/22.
//

import Foundation
import CoreData
import SwiftUI
import AppIntents
import LockKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Lock Intent Entity
@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
struct LockEventEntity: AppEntity, Identifiable {
    
    let id: UUID
    
    /// Date event was created
    let date: Date
    
    /// Key that created this event.
    let key: UUID
    
    /// Type of event
    let type: EventTypeAppEnum
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension LockEventEntity {
    
    static var defaultQuery = LockEventQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Lock Event"
    }
    
    @MainActor
    var displayRepresentation: DisplayRepresentation {
        do {
            let context = Store.shared.managedObjectContext
            guard let managedObject = try EventManagedObject.find(id, in: context) else {
                return defaultDisplayRepresentation
            }
            let (title, subtitle, _) = try managedObject.displayRepresentation(displayLockName: true, in: context)
            return DisplayRepresentation(
                title: "\(title)",
                subtitle: "\(subtitle)\n\(date.formatted(date: .numeric, time: .shortened))",
                image: image
            )
        } catch {
            assertionFailure("Unable to fetch event. \(error)")
            return defaultDisplayRepresentation
        }
    }
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
private extension LockEventEntity {
    
    var defaultDisplayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(String(type.symbol)) \(type.localizedStringResource)", // - \(lock.name ?? "Lock")",
            subtitle: "\(date.formatted(date: .numeric, time: .shortened))",
            image: image
        )
    }
    
    var image: DisplayRepresentation.Image? {
        return DispatchQueue.main.sync {
            let view = Text(verbatim: String(type.symbol))
                .font(.system(size: 43))
            let imageRenderer = ImageRenderer(content: view)
            #if canImport(UIKit)
            return imageRenderer.uiImage?
                .pngData()
                .map { .init(data: $0) }
            #elseif canImport(AppKit)
            return imageRenderer.cgImage
                .map { NSBitmapImageRep(cgImage: $0) }?
                .representation(using: .png, properties: [:])
                .map { .init(data: $0) }
            #else
            return nil
            #endif
        }
    }
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension LockEventEntity {
    
    init?(managedObject: EventManagedObject) {
        guard let id = managedObject.identifier,
              let date = managedObject.date,
              let key = managedObject.key,
              let eventType = EventTypeAppEnum(rawValue: Swift.type(of: managedObject).eventType.rawValue)
            else { return nil }
        
        self.id = id
        self.date = date
        self.key = key
        self.type = eventType
    }
}

@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
extension LockEventEntity {
    
    init(_ value: LockEvent) {
        
        self.id = value.id
        self.date = value.date
        self.key = value.key
        self.type = .init(rawValue: value.type.rawValue)!
    }
}
