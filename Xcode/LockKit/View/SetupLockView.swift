//
//  SetupLockView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/21/22.
//

import SwiftUI
import CoreLock

/// View for lock setup.
public struct SetupLockView: View {
    
    public let id: UUID
    
    public init(id: UUID) {
        self.id = id
    }
    
    public var body: some View {
        Text("Setup this lock on your iOS device.")
    }
}

#if DEBUG
struct SetupLockView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyView()
    }
}
#endif
