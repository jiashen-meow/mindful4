//
//  DeviceActivityMonitorExtension.swift
//  MindfulActivityMonitor
//
//  Created by Jia Shen on 7/20/26.
//

import DeviceActivity
import Foundation

private let sharedSuiteName = "group.mindful3.shared"

// Keys mirroring SharedStore.Keys — duplicated so the extension
// doesn't need to import the main app target.
private enum ExtensionKeys {
    static let thresholdCount     = "thresholdCount"
    static let foulThresholdCount = "foulThresholdCount"
}

private var sharedDefaults: UserDefaults {
    UserDefaults(suiteName: sharedSuiteName)!
}

// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        // New day → reset whichever counter owns this activity.
        switch activity.rawValue {
        case "mindful.daily":
            sharedDefaults.set(0, forKey: ExtensionKeys.thresholdCount)
            print("Interval started: mindful.daily — friend count reset to 0")
        case "foul.daily":
            sharedDefaults.set(0, forKey: ExtensionKeys.foulThresholdCount)
            print("Interval started: foul.daily — foul count reset to 0")
        default:
            break
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        print("Interval ended: \(activity.rawValue)")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        // Parse the milestone index out of the event name:
        //   "milestone_3"      → friend count = 3
        //   "foul_milestone_3" → foul  count = 3
        //
        // Writing the index directly (not += 1) means a delayed or out-of-order
        // delivery self-corrects on the very next milestone.
        let raw = event.rawValue

        if raw.hasPrefix("foul_milestone_") {
            let count = Int(raw.split(separator: "_").last ?? "0") ?? 0
            sharedDefaults.set(count, forKey: ExtensionKeys.foulThresholdCount)
            print("Foul milestone reached — \(raw), foul count = \(count)")
        } else if raw.hasPrefix("milestone_") {
            let count = Int(raw.split(separator: "_").last ?? "0") ?? 0
            sharedDefaults.set(count, forKey: ExtensionKeys.thresholdCount)
            print("Friend milestone reached — \(raw), friend count = \(count)")
        }
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
