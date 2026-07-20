//
//  MindfulActivityMonitor.swift
//  mindful3
//
//  Created by Jia Shen on 9/20/25.
//

import DeviceActivity
internal import ManagedSettings

// MARK: - Activity Names

extension DeviceActivityName {
    /// The primary monitoring schedule for the app.
    /// Replace or add more names here to support multiple schedules.
    static let daily = Self("daily")
}

// MARK: - Event Names

extension DeviceActivityEvent.Name {
    /// Triggered when the user hits a usage threshold you define.
    /// Add more event names here as needed.
    static let usageThresholdReached = Self("usageThresholdReached")
}

// MARK: - Monitor

/// Subclass `DeviceActivityMonitor` in your Device Activity Monitor extension target.
/// Each method is called by the system when a monitored event fires.
class MindfulActivityMonitor: DeviceActivityMonitor {

    let store = ManagedSettingsStore()

    // Called when a monitoring interval starts (e.g. the start of each day).
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // TODO: Set up any ManagedSettings restrictions or state
        // that should apply at the beginning of the interval.
        // Example:
        // store.shield.applications = someApplicationTokens
    }

    // Called when a monitoring interval ends (e.g. end of day).
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // TODO: Clean up or reset any restrictions that were applied
        // during the monitoring interval.
        // Example:
        // store.shield.applications = nil
    }

    // Called each time a DeviceActivityEvent threshold is reached.
    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        switch event {
        case .usageThresholdReached:
            // TODO: React to the user reaching their usage limit.
            // For example, you could apply a shield to restrict further access:
            // store.shield.applications = someApplicationTokens
            break

        default:
            break
        }
    }
}
