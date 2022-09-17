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
    convenience init(lock id: UUID, name: String) {
        
        self.init()
        self.lock = IntentLock(identifier: identifier, name: name)
    }
    
    convenience init(id: UUID, cache: LockCache) {
        
        self.init()
        self.lock = IntentLock(identifier: identifier, name: cache.name)
        
        #if os(iOS) && !targetEnvironment(macCatalyst)
        //self.setImage(INImage(uiImage: UIImage(permission: cache.key.permission)), forParameterNamed: \.lock)
        self.__setImage(INImage(uiImage: UIImage(permission: cache.key.permission)), forParameterNamed: #keyPath(lock))
        #endif
    }
}

@available(iOS 12, iOSApplicationExtension 12.0, watchOS 5.0, *)
public extension IntentLock {
    
    convenience init(id: UUID, name: String) {
        self.init(identifier: identifier.uuidString, display: name, pronunciationHint: name)
    }
}

#if canImport(IntentsUI) && !targetEnvironment(macCatalyst)
import IntentsUI

@available(iOSApplicationExtension 12.0, *)
public extension INUIAddVoiceShortcutViewController {
    
    convenience init(unlock lock: UUID,
                     cache: LockCache,
                     delegate: INUIAddVoiceShortcutViewControllerDelegate) {
        
        let intent = UnlockIntent(identifier: lock, cache: cache)
        self.init(shortcut: .intent(intent))
        self.modalPresentationStyle = .formSheet
        self.delegate = delegate
    }
}

#endif
