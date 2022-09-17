//
//  KeyCredentials.swift
//  
//
//  Created by Alsey Coleman Miller on 9/16/22.
//

import Foundation

public struct KeyCredentials: Equatable {
    
    public let id: UUID
    
    public let secret: KeyData
    
    public init(id: UUID, secret: KeyData) {
        self.id = id
        self.secret = secret
    }
}
