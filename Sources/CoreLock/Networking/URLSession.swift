//
//  URLSession.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 10/16/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import Dispatch

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal extension URLSession {
    
    func synchronousDataTask(with request: URLRequest) throws -> (HTTPURLResponse, Data?) {
        
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask = self.dataTask(with: request) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        if let error = error {
            throw error
        }
        
        guard let urlResponse = response as? HTTPURLResponse
            else { fatalError("Invalid response: \(response?.description ?? "nil")") }
        
        return (urlResponse, data)
    }
}
