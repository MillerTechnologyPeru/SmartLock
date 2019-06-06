//
//  NearbyLockRow.swift
//  Lock
//
//  Created by Alsey Coleman Miller on 6/5/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import SwiftUI
import Bluetooth
import GATT
import DarwinGATT
import CoreLock

struct NearbyLockRow: View {
    
    var title: String
    
    var body: some View {
        Text(verbatim: title)
    }
}

extension NearbyLockRow {
    
    init <Central: CentralProtocol> (_ lock: CoreLock.LockPeripheral<Central>) {
        self.title = lock.scanData.peripheral.description
    }
}

#if DEBUG
extension NearbyLockRow : PreviewProvider {
    static var previews: some View {
        NearbyLockRow(
            title: "\(UUID())"
            )
            .previewLayout(.fixed(width: 300, height: 70))
    }
}
#endif
