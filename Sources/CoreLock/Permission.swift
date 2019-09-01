//
//  Permission.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation
import TLVCoding

/// A Key's permission level.
public enum Permission: Equatable, Hashable {
    
    /// This key belongs to the owner of the lock and has unlimited rights.
    case owner
    
    /// This key can create new keys, and has anytime access.
    case admin
    
    /// This key has anytime access.
    case anytime
    
    /// This key has access during certain hours and can expire.
    case scheduled(Schedule)
}

/// A Key's permission level.
public enum PermissionType: UInt8, Codable {
    
    case owner
    case admin
    case anytime
    case scheduled
}

public extension Permission {
    
    /// Byte value of the permission type.
    var type: PermissionType {
        
        switch self {
        case .owner:        return .owner
        case .admin:        return .admin
        case .anytime:      return .anytime
        case .scheduled(_): return .scheduled
        }
    }
}

public extension Permission {
    
    /// User can administrate the device.
    ///
    /// - View and edit keys.
    /// - View full event history.
    var isAdministrator: Bool {
        switch self {
        case .owner,
             .admin:
            return true
        case .anytime,
             .scheduled:
            return false
        }
    }
}

// MARK: - Schedule

public extension Permission {
    
    /// Specifies the time and dates a permission is valid.
    struct Schedule: Codable, Equatable, Hashable {
        
        /// The date this permission becomes invalid.
        public var expiry: Date
        
        /// The minute interval range the lock can be unlocked.
        public var interval: Interval
        
        /// The days of the week the permission is valid
        public var weekdays: Weekdays
        
        public init(expiry: Date = .distantFuture,
                    interval: Interval = .anytime,
                    weekdays: Weekdays = .all) {
            
            self.expiry = expiry
            self.interval = interval
            self.weekdays = weekdays
        }
        
        /// Verify that the specified date is valid for this schedule.
        public func isValid(for date: Date = Date()) -> Bool {
            
            guard date < expiry else { return false }
            
            // need to get hour and minute of day to validate
            let dateComponents = DateComponents(date: date)
            
            let minutesValue = UInt16(dateComponents.minute * dateComponents.hour)
            
            guard interval.rawValue.contains(minutesValue)
                else { return false }
            
            let canOpenOnDay = weekdays[Int(dateComponents.weekday)]
            
            guard canOpenOnDay else { return false }
            
            return true
        }
    }
}

// MARK: - Schedule Interval

public extension Permission.Schedule {
    
    /// The minute interval range the lock can be unlocked.
    struct Interval: RawRepresentable, Equatable, Hashable {
        
        internal static let min: UInt16 = 0
        
        internal static let max: UInt16 = 1440
        
        /// Interval for anytime access.
        public static let anytime = Interval(Interval.min ... Interval.max)
        
        public let rawValue: ClosedRange<UInt16>
        
        public init?(rawValue: ClosedRange<UInt16>) {
            
            guard rawValue.upperBound <= Interval.max
                else { return nil }
            
            self.rawValue = rawValue
        }
        
        private init(_ unsafe: ClosedRange<UInt16>) {
            
            self.rawValue = unsafe
        }
    }
}

// MARK: - Schedule Weekdays

public extension Permission.Schedule {
    
    struct Weekdays: Codable, Equatable, Hashable {
        
        public var sunday: Bool
        public var monday: Bool
        public var tuesday: Bool
        public var wednesday: Bool
        public var thursday: Bool
        public var friday: Bool
        public var saturday: Bool
        
        public init(sunday: Bool,
                    monday: Bool,
                    tuesday: Bool,
                    wednesday: Bool,
                    thursday: Bool,
                    friday: Bool,
                    saturday: Bool) {
            
            self.sunday = sunday
            self.monday = monday
            self.tuesday = tuesday
            self.wednesday = wednesday
            self.thursday = thursday
            self.friday = friday
            self.saturday = saturday
        }
    }
}

public extension Permission.Schedule.Weekdays {
    
    static let all = Permission.Schedule.Weekdays(
        sunday: true,
        monday: true,
        tuesday: true,
        wednesday: true,
        thursday: true,
        friday: true,
        saturday: true
    )
    
    static let none = Permission.Schedule.Weekdays(
        sunday: false,
        monday: false,
        tuesday: false,
        wednesday: false,
        thursday: false,
        friday: false,
        saturday: false
    )
}

public extension Permission.Schedule.Weekdays {
    
    subscript (weekday: Day) -> Bool {
        
        get {
            switch weekday {
            case .sunday:       return sunday
            case .monday:       return monday
            case .tuesday:      return tuesday
            case .wednesday:    return wednesday
            case .thursday:     return thursday
            case .friday:       return friday
            case .saturday:     return saturday
            }
        }
        
        set {
            switch weekday {
            case .sunday:       sunday = newValue
            case .monday:       monday = newValue
            case .tuesday:      tuesday = newValue
            case .wednesday:    wednesday = newValue
            case .thursday:     thursday = newValue
            case .friday:       friday = newValue
            case .saturday:     saturday = newValue
            }
        }
    }
}

internal extension Permission.Schedule.Weekdays {
    
    subscript (weekday: Int) -> Bool {
        
        // TODO: Verify the day starts at 1 and not 0
        switch weekday {
        case 1: return sunday
        case 2: return monday
        case 3: return tuesday
        case 4: return wednesday
        case 5: return thursday
        case 6: return friday
        case 7: return saturday
        default: fatalError("Invalid weekday \(weekday)")
        }
    }
}

public extension Permission.Schedule.Weekdays {
    
    /// Day of the week.
    enum Day: UInt8, BitMaskOption {
        
        case sunday     = 0b00000001
        case monday     = 0b00000010
        case tuesday    = 0b00000100
        case wednesday  = 0b00001000
        case thursday   = 0b00010000
        case friday     = 0b00100000
        case saturday   = 0b01000000
    }
}

extension Permission.Schedule.Weekdays: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: Day...) {
        self.init(days: .init(elements))
    }
}

public extension Permission.Schedule.Weekdays {
    
    init(days: BitMaskOptionSet<Day>) {
        self = .none
        days.forEach { self[$0] = true }
    }
    
    var days: BitMaskOptionSet<Day> {
        return Day.allCases.reduce(into: BitMaskOptionSet<Day>()) {
            if self[$1] { $0.insert($1) }
        }
    }
}

// MARK: - Codable

extension Permission: Codable {
    
    public enum CodingKeys: String, CodingKey {
        
        case type
        case schedule
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(PermissionType.self, forKey: .type)
        
        switch type {
        case .owner:
            self = .owner
        case .admin:
            self = .admin
        case .anytime:
            self = .anytime
        case .scheduled:
            let schedule = try container.decode(Schedule.self, forKey: .schedule)
            self = .scheduled(schedule)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        switch self {
            
        case .owner,
             .admin,
             .anytime:
            break
            
        case let .scheduled(schedule):
            try container.encode(schedule, forKey: .schedule)
        }
    }
}

extension Permission.Schedule.Interval: Codable {
    
    public enum CodingKeys: String, CodingKey {
        
        case max
        case min
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let min = try container.decode(UInt16.self, forKey: .min)
        let max = try container.decode(UInt16.self, forKey: .max)
        self.init(rawValue: min ... max)! // FIXME: may crash
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(rawValue.lowerBound, forKey: .min)
        try container.encode(rawValue.upperBound, forKey: .max)
    }
}

extension Permission.Schedule.Weekdays: TLVCodable {
        
    public init?(tlvData data: Data) {
        
        guard data.count == 1
            else { return nil }
        
        let days = BitMaskOptionSet<Day>(rawValue: data[0])
        self.init(days: days)
    }
    
    public var tlvData: Data {
        return Data([days.rawValue])
    }
}
