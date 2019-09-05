//
//  EventsView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/4/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import SwiftUI
import CoreLock

/// Lock Events View
@available(iOSApplicationExtension 13.0, *)
public struct EventsView: View {
    
    // MARK: - Properties
    
    @State var events = [Event]()
    
    // MARK: - View
    
    public var body: some View {
        List(events) {
            Cell($0)
        }
    }
}

// MARK: - Supporting Types

@available(iOSApplicationExtension 13.0, *)
public extension EventsView {
    
    struct Event: Identifiable {
        public let id: UUID
        public let lock: Relationship
        public let key: Relationship
    }
    
    struct Relationship: Identifiable {
        public let id: UUID
        public let type: RelationshipType
        public var name: String?
    }
    
    enum RelationshipType {
        case lock
        case key
    }
}

@available(iOSApplicationExtension 13.0, *)
public extension EventsView {
    
    struct Cell: View {
        
        public let icon: Icon
        
        public let title: String
        
        public let keyName: String
        
        public let day: String
        
        public let time: String
        
        public var body: some View {
            VStack {
                HStack {
                    Text(title)
                    Text(keyName)
                }
                HStack {
                    Text(day)
                    Text(time)
                }
            }
        }
    }
}

@available(iOSApplicationExtension 13.0, *)
public extension EventsView.Cell {
    
    enum Icon {
        case setup
        case unlock
        case createNewKey
        case confirmNewKey
        case removeKey
    }
}
