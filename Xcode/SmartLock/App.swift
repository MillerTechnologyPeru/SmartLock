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
            TabBarView()
                .onAppear {
                    _ = LockApp.initialize
                }
                .onContinueUserActivity("") { _ in
                    
                }
        }
    }
    
    static let initialize: () = {
        // print app info
        print("Launching SmartLock v\(Bundle.InfoPlist.shortVersion) Build \(Bundle.InfoPlist.version)")
        
        // set app appearance
        UIView.configureLockAppearance()
    }()
}
