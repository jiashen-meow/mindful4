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
        static let thresholdCount  = "thresholdCount"
    }

    // force-unwrap is safe: the suite name is a compile-time constant
    // that matches the entitlement.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName)!
    }

    // MARK: - Counter

    /// Number of 15-minute milestones reached today.
    /// Written by the extension (derived from the event name), read by the main app.
    static var thresholdCount: Int {
        get { defaults.integer(forKey: Keys.thresholdCount) }
        set { defaults.set(newValue, forKey: Keys.thresholdCount) }
    }

    static func resetThresholdCount() {
        thresholdCount = 0
    }
}
