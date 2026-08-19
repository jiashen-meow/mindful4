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
    static let suiteName = "group.jia.shen.crinkle"

    enum Keys {
        static let thresholdCount     = "thresholdCount"
        static let foeThresholdCount  = "foeThresholdCount"
        static let friendSelection    = "friendSelection"
        static let foeSelection       = "foeSelection"
        static let isMonitoring       = "isMonitoring"
        /// "yyyy-MM-dd" of the day whose counts are currently accumulating.
        /// Written by the main app on startMonitoring / restartBattle.
        /// Advanced to today by whichever .daily activity fires first each midnight.
        static let lastResetDate      = "lastResetDate"
        /// Pending counts — each .daily saves its own count here before resetting
        /// the live count. Cleared once both are present and history is committed.
        static let pendingFriendCount = "pendingFriendCount"
        static let pendingFoeCount    = "pendingFoeCount"
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

    /// foe app: number of 15-minute milestones reached today.
    /// Written by the extension via "foe_milestone_N" event names.
    static var foeThresholdCount: Int {
        get { defaults.integer(forKey: Keys.foeThresholdCount) }
        set { defaults.set(newValue, forKey: Keys.foeThresholdCount) }
    }

    static func resetfoeThresholdCount() {
        foeThresholdCount = 0
    }

    // MARK: - Monitoring flag

    /// True while DeviceActivityCenter is actively monitoring both activities.
    /// Set to true by the main app when startMonitoring() succeeds,
    /// and false when reselect clears the selections.
    static var isMonitoring: Bool {
        get { defaults.bool(forKey: Keys.isMonitoring) }
        set { defaults.set(newValue, forKey: Keys.isMonitoring) }
    }

    /// "yyyy-MM-dd" of the day whose counts are currently accumulating.
    /// Written by the main app on startMonitoring / restartBattle.
    /// Advanced to today by whichever .daily activity fires first each midnight.
    static var lastResetDate: String {
        get { defaults.string(forKey: Keys.lastResetDate) ?? todayString }
        set { defaults.set(newValue, forKey: Keys.lastResetDate) }
    }

    static var todayString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: Date())
    }

    static var yesterdayString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return fmt.string(from: yesterday)
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

//    static func removeFriendSelection() {
//        removeSelection(forKey: Keys.friendSelection)
//    }

    // MARK: foe selection

    static func savefoeSelection(_ selection: FamilyActivitySelection) {
        saveSelection(selection, forKey: Keys.foeSelection)
    }

    static func loadfoeSelection() -> FamilyActivitySelection? {
        loadSelection(forKey: Keys.foeSelection)
    }

//    static func removefoeSelection() {
//        removeSelection(forKey: Keys.foeSelection)
//    }
}
