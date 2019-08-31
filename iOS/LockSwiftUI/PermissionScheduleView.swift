//
//  PermissionScheduleView.swift
//  SmartLock
//
//  Created by Alsey Coleman Miller on 8/30/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import SwiftUI
import CoreLock

@available(iOS 13, *)
public struct PermissionScheduleView: View {
    
    // MARK: - Properties
    
    @State
    public var schedule = Permission.Schedule()
    
    let action: () -> Void = {
        print("🐀🐀")
    }
    
    // MARK: - View
    
    public var body: some View {
        
        List{
            Section(header: Text(verbatim: "Header")) {
                Text(verbatim: "All Day")
                Button(action: {
                    print("🐀🐀")
                }) {
                    Text(verbatim: "Text Button")
                        .foregroundColor(.white)
                        .bold()
                }
                DatePicker(selection: $schedule.expiry, displayedComponents: .hourAndMinute) {
                    Text(verbatim: "Date Picker")
                }
            }
            
            Divider()
                
            HStack{
                Button(action: action) {
                    Text(verbatim: "A")
                        .foregroundColor(.white)
                }
                Button(action: action) {
                    Text(verbatim: "B")
                        .foregroundColor(.white)
                }
                Button(action: action) {
                    Text(verbatim: "C")
                        .foregroundColor(.white)
                }
                .foregroundColor(.yellow)
                .clipShape(Circle())
            }
        }
        .listStyle(ListStyle())
        .navigationBarTitle(Text("NavigationBar"))
    }
    
}

@available(iOS 13, *)
public struct DayView: View {
    
    // MARK: - View
    
    public var body: some View {
        Text(verbatim: "Text")
    }
}

@available(iOS 13, *)
extension PermissionScheduleView {
    
    #if os(iOS)
    typealias ListStyle = GroupedListStyle
    #elseif os(watchOS)
    typealias ListStyle = CarouselListStyle
    #endif
}

#if DEBUG
@available(iOS 13, *)
struct DayViewPreview: PreviewProvider {
    static var previews: some View {
        DayView()
    }
}
#endif
