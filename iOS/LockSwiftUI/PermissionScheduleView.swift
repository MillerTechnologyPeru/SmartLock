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

/// Permission Schedule View
@available(iOS 13, *)
public struct PermissionScheduleView: View {
    
    // MARK: - Properties
    
    public init(schedule: Permission.Schedule = .init()) {
        self.schedule = schedule
    }
    
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
    
    private var intervalStart: Binding<Date> {
        return Binding(get: {
            let minutes = self.schedule.interval.rawValue.lowerBound
            return self.date(from: minutes)
        }, set: {
            let minutes = self.minutes(from: $0)
            guard let interval = Permission.Schedule.Interval(rawValue: minutes ... self.schedule.interval.rawValue.upperBound) else {
                assertionFailure()
                return
            }
            self.schedule.interval = interval
            self.defaultInterval = interval
        })
    }
    
    private var intervalEnd: Binding<Date> {
        return Binding(get: {
            let minutes = self.schedule.interval.rawValue.upperBound
            return self.date(from: minutes)
        }, set: {
            let minutes = self.minutes(from: $0)
            guard let interval = Permission.Schedule.Interval(rawValue:  self.schedule.interval.rawValue.lowerBound ... minutes) else {
                assertionFailure()
                return
            }
            self.schedule.interval = interval
            self.defaultInterval = interval
        })
    }
    
    private func minutes(from date: Date) -> UInt16 {
        return UInt16(date.timeIntervalSinceReferenceDate / 60)
    }
    
    private func date(from minutes: UInt16) -> Date {
        return Date(timeIntervalSinceReferenceDate: TimeInterval(minutes) * 60)
    }
    
    private func toggle(_ weekday: Permission.Schedule.Weekdays.Day) {
        
        var weekdays = schedule.weekdays
        weekdays[weekday].toggle()
        guard weekdays != .none else { return }
        self.schedule.weekdays = weekdays // set new value
    }
    
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
                        selection: intervalStart,
                        displayedComponents: [.hourAndMinute],
                        label: { Text("Start") }
                    )
                    DatePicker(
                        selection: intervalEnd,
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
                    DatePicker(selection: expiration) { Text(verbatim: " ") }
                }
            }
            
            Section(header: Text(verbatim: "Days"), footer: SectionBottom(weekdays: schedule.weekdays)) {
                HStack {
                    Spacer()
                    Text(verbatim: "S")
                        .modifier(RoundText(enabled: schedule.weekdays.sunday))
                        .onTapGesture { self.toggle(.sunday) }
                    Text(verbatim: "M")
                        .modifier(RoundText(enabled: schedule.weekdays.monday))
                        .onTapGesture { self.toggle(.monday) }
                    Text(verbatim: "T")
                        .modifier(RoundText(enabled: schedule.weekdays.tuesday))
                        .onTapGesture { self.toggle(.tuesday) }
                    Text(verbatim: "W")
                        .modifier(RoundText(enabled: schedule.weekdays.wednesday))
                        .onTapGesture { self.toggle(.wednesday) }
                    Text(verbatim: "T")
                        .modifier(RoundText(enabled: schedule.weekdays.thursday))
                        .onTapGesture { self.toggle(.thursday) }
                    Text(verbatim: "F")
                        .modifier(RoundText(enabled: schedule.weekdays.friday))
                        .onTapGesture { self.toggle(.friday) }
                    Text(verbatim: "S")
                        .modifier(RoundText(enabled: schedule.weekdays.saturday))
                        .onTapGesture { self.toggle(.saturday) }
                    Spacer()
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text("Schedule"))
    }
}

@available(iOS 13, *)
public extension PermissionScheduleView {
    
    struct Modal: View {
        
        public init(done: ((Permission.Schedule) -> ())? = nil,
                    cancel: (() -> ())? = nil) {
            self.cancel = cancel
            self.done = done
        }

        public var done: ((Permission.Schedule) -> ())?
        
        public var cancel: (() -> ())?
        
        private var scheduleView = PermissionScheduleView()
        
        public var body: some View {
            
            NavigationView {
                scheduleView
                .navigationBarItems(
                    leading: Button(
                        action: { self.cancel?() },
                        label: { Text("Cancel") }
                    ),
                    trailing: Button(
                        action: { self.done?(self.scheduleView.schedule) },
                        label: { Text("Done") }
                    )
                )
            }
        }
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
