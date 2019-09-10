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
    private var schedule = Permission.Schedule()
    
    func isAllDaysSelected() -> Bool {
        
        return schedule.weekdays == .all
    }
    
    // MARK: - View
    
    public var body: some View {
        
        Form {
            Section {
                Button(action: {
                    if self.isAllDaysSelected() {
                        
                        self.schedule.weekdays = .none
                    } else {
                        
                        self.schedule.weekdays = .all
                    }
                }) {
                    HStack {
                        if isAllDaysSelected() {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color.orange)
                        }
                        Text(verbatim: "All Days")
                            .foregroundColor(Color.primary)
                    }
                }
                
                DatePicker(selection: $schedule.expiry, displayedComponents: .hourAndMinute) {
                    Text(verbatim: "Expiry Date")
                }
            }
            
            Section(header: Text(verbatim: "Repeat"), footer: SectionBottom(weekdays: schedule.weekdays)) {
                HStack {
                    Spacer()
                    Text(verbatim: "S")
                        .modifier(RoundText(enabled: schedule.weekdays.sunday))
                        .onTapGesture {
                            self.schedule.weekdays.sunday.toggle()
                        }
                    Text(verbatim: "M")
                        .modifier(RoundText(enabled: schedule.weekdays.monday))
                        .onTapGesture {
                            self.schedule.weekdays.monday.toggle()
                        }
                    Text(verbatim: "T")
                        .modifier(RoundText(enabled: schedule.weekdays.tuesday))
                        .onTapGesture {
                            self.schedule.weekdays.tuesday.toggle()
                        }
                    Text(verbatim: "W")
                        .modifier(RoundText(enabled: schedule.weekdays.wednesday))
                        .onTapGesture {
                            self.schedule.weekdays.wednesday.toggle()
                        }
                    Text(verbatim: "T")
                        .modifier(RoundText(enabled: schedule.weekdays.thursday))
                        .onTapGesture {
                            self.schedule.weekdays.thursday.toggle()
                        }
                    Text(verbatim: "F")
                        .modifier(RoundText(enabled: schedule.weekdays.friday))
                        .onTapGesture {
                            self.schedule.weekdays.friday.toggle()
                        }
                    Text(verbatim: "S")
                        .modifier(RoundText(enabled: schedule.weekdays.saturday))
                        .onTapGesture {
                            self.schedule.weekdays.saturday.toggle()
                        }
                    Spacer()
                }
            }
        }
        .navigationBarTitle(Text("Permission Schedule"))
    }
}

struct RoundText: ViewModifier {
    
    // MARK: - Properties
    let enabled: Bool
    
    // MARK: - View Modifier
    func body(content: Content) -> some View {
        content
            .frame(width: 15, height: 15)
            .padding(10)
            .foregroundColor(Color.white)
            .background(color)
            .mask(Circle())
    }
}

extension RoundText {
    
    // MARK: - Properties
    var color: SwiftUI.Color {
        return enabled ? .orange : .gray
    }
}

public struct SectionBottom: View {
    
    // MARK: - Properties
    let weekdays: Permission.Schedule.Weekdays
    
    // MARK: - View
    
    public var body: some View {
        Text(verbatim: weekdays.localizedText)
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
        PermissionScheduleView()
    }
}
#endif
