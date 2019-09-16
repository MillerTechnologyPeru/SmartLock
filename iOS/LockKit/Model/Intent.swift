//
//  Intent.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import Intents

#if os(iOS)
import UIKit
#endif

@available(iOS 12, iOSApplicationExtension 12.0, watchOS 5.0, *)
public extension UnlockIntent {
    
    @available(*, deprecated)
    convenience init(lock identifier: UUID, name: String) {
        
        self.init()
        self.lock = IntentLock(identifier: identifier, name: name)
    }
    
    convenience init(identifier: UUID, cache: LockCache) {
        
        self.init()
        self.lock = IntentLock(identifier: identifier, name: cache.name)
        
        #if os(iOS)
        //self.setImage(INImage(uiImage: UIImage(permission: cache.key.permission)), forParameterNamed: \.lock)
        self.__setImage(INImage(uiImage: UIImage(permission: cache.key.permission)), forParameterNamed: #keyPath(lock))
        #endif
    }
    
    static var any: UnlockIntent {
        let intent = UnlockIntent()
        intent.suggestedInvocationPhrase = "Unlock"
        return intent
    }
}

@available(iOS 12, iOSApplicationExtension 12.0, watchOS 5.0, *)
public extension IntentLock {
    
    convenience init(identifier: UUID, name: String) {
        self.init(identifier: identifier.uuidString, display: name, pronunciationHint: name)
    }
}
