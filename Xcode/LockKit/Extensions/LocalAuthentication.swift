//
//  LocalAuthentication.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/19/22.
//

#if canImport(LocalAuthentication) && os(iOS) || os(macOS)
import Foundation
import LocalAuthentication

extension LAContext {
        
    func canEvaluate(policy: LAPolicy) throws -> Bool {
        var error: NSError?
        let result = canEvaluatePolicy(policy, error: &error)
        if let error = error {
            throw error
        }
        return result
    }
}
#endif
