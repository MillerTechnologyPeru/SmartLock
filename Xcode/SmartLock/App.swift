//
//  SmartLockApp.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import SwiftUI

@main
struct LockApp: App {
    
    //let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            NearbyDevicesView()
                //.environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
