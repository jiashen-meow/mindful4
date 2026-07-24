//
//  SharedStore.swift
//  mindful3
//
//  Created by Jia Shen on 7/20/26.
//
//  Shared UserDefaults suite used by both the main app and the
//  MindfulActivityMonitor extension. Both targets must belong to the
//  App Group "group.mindful3.shared" (set in Signing & Capabilities).
//

import Foundation
import FamilyControls

enum SharedStore {
    // Must match the App Group identifier added in Xcode → Signing & Capabilities.
    static let suiteName = "group.mindful3.shared"

    enum Keys {
        static let thresholdCount     = "thresholdCount"
        static let foulThresholdCount = "foulThresholdCount"
        static let friendSelection    = "friendSelection"
        static let foulSelection      = "foulSelection"
        static let isMonitoring       = "isMonitoring"
        static let lastResetDate      = "lastResetDate"
    }

    // force-unwrap is safe: the suite name is a compile-time constant
    // that matches the entitlement.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName)!
    }

    // MARK: - Counters

    /// Friend app: number of 15-minute milestones reached today.
    /// Written by the extension via "milestone_N" event names.
    static var thresholdCount: Int {
        get { defaults.integer(forKey: Keys.thresholdCount) }
        set { defaults.set(newValue, forKey: Keys.thresholdCount) }
    }

    static func resetThresholdCount() {
        thresholdCount = 0
    }

    /// Foul app: number of 15-minute milestones reached today.
    /// Written by the extension via "foul_milestone_N" event names.
    static var foulThresholdCount: Int {
        get { defaults.integer(forKey: Keys.foulThresholdCount) }
        set { defaults.set(newValue, forKey: Keys.foulThresholdCount) }
    }

    static func resetFoulThresholdCount() {
        foulThresholdCount = 0
    }

    // MARK: - Monitoring flag

    /// True while DeviceActivityCenter is actively monitoring both activities.
    /// Set to true by the main app when startMonitoring() succeeds,
    /// and false when reselect clears the selections.
    static var isMonitoring: Bool {
        get { defaults.bool(forKey: Keys.isMonitoring) }
        set { defaults.set(newValue, forKey: Keys.isMonitoring) }
    }

    // MARK: - Last reset date

    /// The calendar day (yyyy-MM-dd) on which the counts were last reset.
    /// Used by the monitor extension to distinguish a genuine new-day rollover
    /// from an initial startMonitoring() call on the same day.
    static var lastResetDate: String {
        get { defaults.string(forKey: Keys.lastResetDate) ?? "" }
        set { defaults.set(newValue, forKey: Keys.lastResetDate) }
    }

    static var todayString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    // MARK: - Selections

    /// Persists a `FamilyActivitySelection` under the given key.
    private static func saveSelection(_ selection: FamilyActivitySelection, forKey key: String) {
        guard let data = try? JSONEncoder().encode(selection) else {
            print("SharedStore: failed to encode FamilyActivitySelection for key '\(key)'")
            return
        }
        defaults.set(data, forKey: key)
    }

    /// Loads a `FamilyActivitySelection` from the given key, or returns `nil` if nothing is stored.
    private static func loadSelection(forKey key: String) -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    /// Removes the stored selection for the given key.
    private static func removeSelection(forKey key: String) {
        defaults.removeObject(forKey: key)
    }

    // MARK: Friend selection

    static func saveFriendSelection(_ selection: FamilyActivitySelection) {
        saveSelection(selection, forKey: Keys.friendSelection)
    }

    static func loadFriendSelection() -> FamilyActivitySelection? {
        loadSelection(forKey: Keys.friendSelection)
    }

    static func removeFriendSelection() {
        removeSelection(forKey: Keys.friendSelection)
    }

    // MARK: Foul selection

    static func saveFoulSelection(_ selection: FamilyActivitySelection) {
        saveSelection(selection, forKey: Keys.foulSelection)
    }

    static func loadFoulSelection() -> FamilyActivitySelection? {
        loadSelection(forKey: Keys.foulSelection)
    }

    static func removeFoulSelection() {
        removeSelection(forKey: Keys.foulSelection)
    }
}
