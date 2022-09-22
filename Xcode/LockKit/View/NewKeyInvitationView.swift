//
//  NewKeyInvitationView.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 9/21/22.
//

import SwiftUI
import CoreLock

public struct NewKeyInvitationView: View {
    
    @EnvironmentObject
    public var store: Store
    
    public let newKey: NewKey.Invitation
    
    public init(newKey: NewKey.Invitation) {
        self.newKey = newKey
    }
    
    public var body: some View {
        Text("")
    }
}

internal extension NewKeyInvitationView {
    
    
}

#if DEBUG
struct NewKeyInvitationView_Previews: PreviewProvider {
    static var previews: some View {
        //NewKeyInvitationView()
        EmptyView()
    }
}
#endif
