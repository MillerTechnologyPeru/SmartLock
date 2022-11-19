//
//  Date.swift
//  
//
//  Created by Alsey Coleman Miller on 9/16/22.
//

import Foundation

internal extension Date {
    
    var removingMiliseconds: Date {
        Date(timeIntervalSinceReferenceDate: Double(Int(self.timeIntervalSinceReferenceDate)))
    }
}
