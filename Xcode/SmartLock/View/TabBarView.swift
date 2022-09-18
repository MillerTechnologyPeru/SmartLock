//
//  TabBarView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 9/18/22.
//

import SwiftUI

struct TabBarView: View {
    var body: some View {
        NavigationView {
            TabView {
                NearbyDevicesView()
            }
            .navigationTitle("Hey")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView()
    }
}
