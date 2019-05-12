//
//  Permission.swift
//  CoreLock
//
//  Created by Alsey Coleman Miller on 8/11/18.
//

import Foundation

#if swift(>=3.2)
#elseif swift(>=3.0)
    import Codable
#endif

/// A Key's permission level.
public enum PermissionType: UInt8, Codable {
    
    case owner
    case admin
    case anytime
    case scheduled
}

/// A Key's permission level.
public enum Permission {
    
    /// This key belongs to the owner of the lock and has unlimited rights.
    case owner
    
    /// This key can create new keys, and has anytime access.
    case admin
    
    /// This key has anytime access.
    case anytime
    
    /// This key has access during certain hours and can expire.
    case scheduled(Schedule)
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

extension Permission: Equatable {
    
    public static func == (lhs: Permission, rhs: Permission) -> Bool {
        
        switch (lhs, rhs) {
            
        case (.owner, .owner): return true
        case (.admin, .admin): return true
        case (.anytime, .anytime): return true
        case let (.scheduled(lhsSchedule), .scheduled(rhsSchedule)): return lhsSchedule == rhsSchedule
            
        default: return false
        }
    }
}

// MARK: - Schedule

public extension Permission {
    
    /// Specifies the time and dates a permission is valid.
    struct Schedule {
        
        /// The date this permission becomes invalid.
        public var expiry: Date
        
        /// The minute interval range the lock can be unlocked.
        public var interval: Interval
        
        /// The days of the week the permission is valid
        public var weekdays: Weekdays
        
        public init(expiry: Date,
                    interval: Interval = .anytime,
                    weekdays: Weekdays) {
            
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

extension Permission.Schedule: Equatable {
    
    public static func == (lhs: Permission.Schedule, rhs: Permission.Schedule) -> Bool {
        
        return lhs.expiry == rhs.expiry
            && lhs.interval == rhs.interval
            && lhs.weekdays == rhs.weekdays
    }
}

// MARK: - Schedule Interval

public extension Permission.Schedule {
    
    /// The minute interval range the lock can be unlocked.
    struct Interval: RawRepresentable {
        
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

extension Permission.Schedule.Interval: Equatable {
    
    public static func == (lhs: Permission.Schedule.Interval, rhs: Permission.Schedule.Interval) -> Bool {
        
        return lhs.rawValue == rhs.rawValue
    }
}

// MARK: - Schedule Weekdays

public extension Permission.Schedule {
    
    struct Weekdays {
        
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
        
        public subscript (weekday: Int) -> Bool {
            
            get {
                
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
            
            set {
                
                switch weekday {
                    
                case 1: sunday = newValue
                case 2: monday = newValue
                case 3: tuesday = newValue
                case 4: wednesday = newValue
                case 5: thursday = newValue
                case 6: friday = newValue
                case 7: saturday = newValue
                
                default: fatalError("Invalid weekday \(weekday)")
                }
            }
        }
    }
}

extension Permission.Schedule.Weekdays: Equatable {
    
    public static func == (lhs: Permission.Schedule.Weekdays, rhs: Permission.Schedule.Weekdays) -> Bool {
        
        return lhs.sunday == rhs.sunday
            && lhs.monday == rhs.monday
            && lhs.tuesday == rhs.tuesday
            && lhs.wednesday == rhs.wednesday
            && lhs.thursday == rhs.thursday
            && lhs.friday == rhs.friday
            && lhs.saturday == rhs.saturday
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

extension Permission.Schedule: Codable {
    
    public enum CodingKeys: String, CodingKey {
        
        case expiry
        case interval
        case weekdays
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.expiry = try container.decode(Date.self, forKey: .expiry)
        self.interval = try container.decode(Interval.self, forKey: .interval)
        self.weekdays = try container.decode(Weekdays.self, forKey: .weekdays)
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(expiry, forKey: .expiry)
        try container.encode(interval, forKey: .interval)
        try container.encode(weekdays, forKey: .weekdays)
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

extension Permission.Schedule.Weekdays: Codable {
    
    public enum CodingKeys: String, CodingKey {
        
        case sunday
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday
    }
    
    public init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.sunday = try container.decode(Bool.self, forKey: .sunday)
        self.monday = try container.decode(Bool.self, forKey: .monday)
        self.tuesday = try container.decode(Bool.self, forKey: .tuesday)
        self.wednesday = try container.decode(Bool.self, forKey: .wednesday)
        self.thursday = try container.decode(Bool.self, forKey: .thursday)
        self.friday = try container.decode(Bool.self, forKey: .friday)
        self.saturday = try container.decode(Bool.self, forKey: .saturday)
    }
    
    public func encode(to encoder: Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(sunday, forKey: .sunday)
        try container.encode(monday, forKey: .monday)
        try container.encode(tuesday, forKey: .tuesday)
        try container.encode(wednesday, forKey: .wednesday)
        try container.encode(thursday, forKey: .thursday)
        try container.encode(friday, forKey: .friday)
        try container.encode(saturday, forKey: .saturday)
    }
}
