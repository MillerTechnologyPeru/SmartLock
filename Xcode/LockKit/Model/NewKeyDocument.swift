//
//  NewKeyDocument.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/25/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

#if canImport(UIKit)
import Foundation
import CoreLock
import UIKit

/// New Key Document
public final class NewKeyDocument: UIDocument {
    
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
#endif
