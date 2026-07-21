//
//  DeviceActivityMonitorExtension.swift
//  MindfulActivityMonitor
//
//  Created by Jia Shen on 7/20/26.
//

import DeviceActivity
import Foundation

private let sharedSuiteName = "group.mindful3.shared"
private let thresholdCountKey = "thresholdCount"

private var sharedDefaults: UserDefaults {
    UserDefaults(suiteName: sharedSuiteName)!
}

// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        // New day → reset the counter so the main app always sees today's hit count.
        sharedDefaults.set(0, forKey: thresholdCountKey)
        print("Interval started: \(activity.rawValue) — count reset to 0")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        print("Interval ended: \(activity.rawValue)")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        // Event names are "milestone_1", "milestone_2", … so the number is the
        // canonical hit count. Using it directly (instead of += 1) means a
        // delayed or missed delivery self-corrects on the very next milestone.
        let count = Int(event.rawValue.split(separator: "_").last ?? "0") ?? 0
        sharedDefaults.set(count, forKey: thresholdCountKey)
        print("Milestone reached — \(event.rawValue), count = \(count)")
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
    }
}
