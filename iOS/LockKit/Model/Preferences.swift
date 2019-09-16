//
//  Preferences.swift
//  LockKit
//
//  Created by Alsey Coleman Miller on 8/22/19.
//  Copyright © 2019 ColemanCDA. All rights reserved.
//

import Foundation
import Combine

/// Preferences
public final class Preferences {
    
    // MARK: - Preferences
    
    private let userDefaults: UserDefaults
        
    @available(iOS 13.0, watchOS 6.0, *)
    public lazy var objectWillChange = ObservableObjectPublisher()
    
    // MARK: - Initialization
    
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Methods
    
    private subscript <T> (key: Key) -> T? {
        get { userDefaults.object(forKey: key.rawValue) as? T }
        set {
            if #available(iOS 13.0, watchOSApplicationExtension 6.0, *) {
                objectWillChange.send()
            }
            userDefaults.set(newValue, forKey: key.rawValue)
        }
    }
}

// MARK: - ObservableObject

@available(iOS 13.0, watchOS 6.0, *)
extension Preferences: ObservableObject { }

// MARK: - App Group

public extension Preferences {
    
    static let standard = Preferences(userDefaults: .standard)
}

public extension Preferences {
    
    convenience init?(suiteName appGroup: AppGroup) {
        guard let userDefaults = UserDefaults(suiteName: appGroup)
            else { return nil }
        self.init(userDefaults: userDefaults)
    }
}

public extension UserDefaults {
    
    /// Creates a user defaults object initialized with the defaults for the specified database name.
    convenience init?(suiteName appGroup: AppGroup) {
        self.init(suiteName: appGroup.rawValue)
    }
}

// MARK: - Accessors

public extension Preferences {
    
    var isAppInstalled: Bool {
        get { return self[.isAppInstalled] ?? false }
        set { self[.isAppInstalled] = newValue }
    }
    
    var isCloudEnabled: Bool {
        get {
            #if os(iOS)
            #if targetEnvironment(macCatalyst) || targetEnvironment(simulator)
            let defaultValue = true
            #else
            let defaultValue = false
            #endif
            #elseif os(tvOS) || os(watchOS) || os(macOS)
            let defaultValue = true
            #else
            let defaultValue = false
            #endif
            return self[.isCloudEnabled] ?? defaultValue
        }
        set { self[.isCloudEnabled] = newValue }
    }
    
    var lastCloudUpdate: Date? {
        get { return self[.lastCloudUpdate] }
        set { self[.lastCloudUpdate] = newValue }
    }
    
    var lastWatchUpdate: Date? {
        get { return self[.lastWatchUpdate] }
        set { self[.lastWatchUpdate] = newValue }
    }
    
    var bluetoothTimeout: TimeInterval {
        get { return self[.bluetoothTimeout] ?? 30.0 }
        set { self[.bluetoothTimeout] = newValue }
    }
    
    var scanDuration: TimeInterval {
        get { return self[.scanDuration] ?? 5.0 }
        set { self[.scanDuration] = newValue }
    }
    
    var filterDuplicates: Bool {
        get { return self[.filterDuplicates] ?? true }
        set { self[.filterDuplicates] = newValue }
    }
    
    var writeWithoutResponseTimeout: TimeInterval {
        get { return self[.writeWithoutResponseTimeout] ?? 3.0 }
        set { self[.writeWithoutResponseTimeout] = newValue }
    }
    
    var showPowerAlert: Bool {
        get { return self[.showPowerAlert] ?? false }
        set { self[.showPowerAlert] = newValue }
    }
}

// MARK: - Supporting Types

public extension Preferences {
    
    enum Key: String, CaseIterable {
        
        case isAppInstalled
        case isCloudEnabled
        case lastCloudUpdate
        case lastWatchUpdate
        
        case bluetoothTimeout
        case filterDuplicates
        case showPowerAlert
        case writeWithoutResponseTimeout
        case scanDuration
    }
}
