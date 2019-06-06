//
//  UserData.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 6/6/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Combine
import SwiftUI

final class UserData: BindableObject {
    
    let didChange = PassthroughSubject<UserData, Never>()
    
    var scanResults = [LockPeripheral]() {
        didSet { didChange.send(self) }
    }
    
    var scanDuration: TimeInterval = 3.0 {
        didSet { didChange.send(self) }
    }
}
