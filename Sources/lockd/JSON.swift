//
//  JSON.swift
//  lockd
//
//  Created by Alsey Coleman Miller on 6/28/19.
//

import Foundation

internal extension JSONDecoder {
    
    func decode <T: Decodable> (_ type: T.Type, from url: URL) throws -> T {
        
        let data = try Data(contentsOf: url)
        return try self.decode(type, from: data)
    }
}
