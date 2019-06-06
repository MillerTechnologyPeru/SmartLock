//
//  NearbyLocksList.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 6/5/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import SwiftUI
import Bluetooth
import GATT
import CoreLock

struct NearbyLocksList: View {
    
    @EnvironmentObject private var store: Store
    
    typealias LockPeripheral = CoreLock.LockPeripheral<NativeCentral>
    
    var scanResults = [LockPeripheral]()
    
    var body: some View {
        List {
            ForEach(self.scanResults) {
                NearbyLockRow($0)
            }
        }
    }
}

/*
#if DEBUG
struct NearbyLocksList_Previews : PreviewProvider {
    static var previews: some View {
        NearbyLocksList()
    }
}
#endif
*/
