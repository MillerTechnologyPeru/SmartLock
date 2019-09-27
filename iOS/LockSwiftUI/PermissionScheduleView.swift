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
    
    @State
    private var defaultExpiration = Date() + (60 * 60 * 24)
    
    @State
    private var defaultInterval: Permission.Schedule.Interval = .default
    
    private var expiration: Binding<Date> {
        return Binding(get: {
            return self.schedule.expiry ?? self.defaultExpiration
        }, set: {
            self.schedule.expiry = $0
            self.defaultExpiration = $0
        })
    }
    
    private var doesExpire: Bool {
        return self.schedule.expiry != nil
    }
    
    private var isCustomSchedule: Bool {
        return self.schedule.interval != .anytime
    }
    
    private var showExpirationPicker: Binding<Bool> {
        return Binding(get: {
            return self.schedule.expiry != nil
        }, set: { (showPicker) in
            if showPicker {
                self.schedule.expiry = self.schedule.expiry ?? self.defaultExpiration
            } else {
                self.schedule.expiry = nil
            }
        })
    }
    
    private var checkmark: some View {
        return Image(systemName: "checkmark")
            .foregroundColor(Color.orange)
    }
    
    private static let expirationTimeFormatter = RelativeDateTimeFormatter()
    
    private func expirationTime(for date: Date) -> Text {
        return Text(verbatim: type(of: self).expirationTimeFormatter
            .localizedString(for: date, relativeTo: Date()))
    }
    
    private static let intervalTimeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        return formatter
    }()
    
    // MARK: - View
    
    public var body: some View {
        
        Form {
            
            Section(header: Text(verbatim: "Time")) {
                Button(action: { self.schedule.interval = .anytime }) {
                    HStack {
                        if self.schedule.interval == .anytime {
                            self.checkmark
                        }
                        Text(verbatim: "Any time")
                            .foregroundColor(Color.primary)
                    }
                }
                Button(action: { self.schedule.interval = self.defaultInterval }) {
                    HStack {
                        if isCustomSchedule {
                            self.checkmark
                        }
                        Text(verbatim: "Scheduled")
                            .foregroundColor(Color.primary)
                    }
                }
                if isCustomSchedule {
                    DatePicker(
                        selection: expiration,
                        displayedComponents: [.hourAndMinute],
                        label: { Text("Start") }
                    )
                    DatePicker(
                        selection: expiration,
                        displayedComponents: [.hourAndMinute],
                        label: { Text("End") }
                    )
                }
            }
            
            Section(header: Text(verbatim: "Expires")) {
                Toggle(isOn: showExpirationPicker) {
                    schedule.expiry.flatMap({ expirationTime(for: $0) }) ?? Text("Never")
                }
                if showExpirationPicker.wrappedValue {
                    DatePicker(selection: expiration, label: { Text(" ") })
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
        .navigationBarTitle(Text("Schedule"))
    }
}

@available(iOS 13, *)
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

@available(iOS 13, *)
extension RoundText {
    
    // MARK: - Properties
    var color: SwiftUI.Color {
        return enabled ? .orange : .gray
    }
}

@available(iOS 13, *)
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
        Group {
            
            NavigationView {
                PermissionScheduleView()
            }
            .previewDevice("iPhone SE")
            
            NavigationView {
                PermissionScheduleView()
            }
            .previewDevice("iPhone SE")
            .environment(\.colorScheme, .dark)
            
            NavigationView {
                PermissionScheduleView()
            }
            .previewDevice("iPhone XR")
            .environment(\.colorScheme, .dark)
        }
    }
}
#endif
