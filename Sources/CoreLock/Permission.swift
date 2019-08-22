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
    
    /// Whether the permission allows for sharing keys.
    var canShareKeys: Bool {
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
        
        public static let all = Weekdays(
            sunday: true,
            monday: true,
            tuesday: true,
            wednesday: true,
            thursday: true,
            friday: true,
            saturday: true
        )
        
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
    
    internal static var length: Int { return 7 }
    
    public init?(tlvData data: Data) {
        
        guard data.count == type(of: self).length
            else { return nil }
        
        guard let sunday = Bool(byteValue: data[0]),
            let monday = Bool(byteValue: data[1]),
            let tuesday = Bool(byteValue: data[2]),
            let wednesday = Bool(byteValue: data[3]),
            let thursday = Bool(byteValue: data[4]),
            let friday = Bool(byteValue: data[5]),
            let saturday = Bool(byteValue: data[6])
            else { return nil }
        
        self.sunday = sunday
        self.monday = monday
        self.tuesday = tuesday
        self.wednesday = wednesday
        self.thursday = thursday
        self.friday = friday
        self.saturday = saturday
    }
    
    public var tlvData: Data {
        
        return Data([
            sunday.byteValue,
            monday.byteValue,
            tuesday.byteValue,
            wednesday.byteValue,
            thursday.byteValue,
            friday.byteValue,
            saturday.byteValue
            ])
    }
}
