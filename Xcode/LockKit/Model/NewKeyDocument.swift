//
//  NewKeyDocument.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/25/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import CoreLock
import SwiftUI
import UniformTypeIdentifiers

@available(iOS 14.0, macOS 11.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public extension NewKey.Invitation {
    
    /// New Key Invitation File Document
    struct Document: FileDocument {
                
        /// The types the document is able to open.
        public static var readableContentTypes: [UTType] {
            return [.json]
        }
        
        public init(configuration: ReadConfiguration) throws {
            fatalError()
        }
        
        public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
            fatalError()
        }
    }
}

#if canImport(UIKit)
import UIKit

public extension UIDocument {
    
    /// New Key Invitation Document
    final class NewKeyInvitation: UIDocument {
        
        // MARK: - Properties
        
        public private(set) var invitation: NewKey.Invitation?
        
        private lazy var encoder = JSONEncoder()
        
        private lazy var decoder = JSONDecoder()
        
        // MARK: - Methods
        
        public override func contents(forType typeName: String) throws -> Any {
            
            guard let invitation = self.invitation else { return Data() }
            return try encoder.encode(invitation)
        }
        
        public override func load(fromContents contents: Any, ofType typeName: String?) throws {
            
            guard let data = contents as? Data else { return }
            self.invitation = try decoder.decode(NewKey.Invitation.self, from: data)
        }
    }
}
#endif
