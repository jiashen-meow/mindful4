//
//  DeviceActivityMonitorExtension.swift
//  MindfulActivityMonitor
//
//  Created by Jia Shen on 7/20/26.
//

import DeviceActivity
import Foundation
import WidgetKit

private let sharedSuiteName = "group.jia.shen.quicato"

// Keys mirroring SharedStore.Keys — duplicated so the extension
// doesn't need to import the main app target.
// Suite name must match SharedStore.suiteName and the App Group entitlement in both targets.
private enum ExtensionKeys {
    static let thresholdCount     = "thresholdCount"
    static let foulThresholdCount = "foulThresholdCount"
    static let lastResetDate      = "lastResetDate"
    static let battleHistory      = "battleHistory"
}

// MARK: - Midnight result persistence

/// Reads yesterday's counts and writes the battle result to the history dictionary
/// before the counts are reset. Mirrors HistoryStore logic without importing the main target.
private func saveYesterdayResult(using defaults: UserDefaults) {
    let friendCount = defaults.integer(forKey: ExtensionKeys.thresholdCount)
    let foulCount   = defaults.integer(forKey: ExtensionKeys.foulThresholdCount)

    let result: String
    if friendCount > foulCount   { result = "win"  }
    else if foulCount > friendCount { result = "loss" }
    else                           { result = "draw" }

    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    // At midnight the "previous" day is still "yesterday" relative to the new day.
    let yesterday = fmt.string(
        from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
    )

    // Read → mutate → write the history dict.
    var history: [String: String]
    if let data = defaults.data(forKey: ExtensionKeys.battleHistory),
       let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
        history = decoded
    } else {
        history = [:]
    }

    history[yesterday] = result

    if let encoded = try? JSONEncoder().encode(history) {
        defaults.set(encoded, forKey: ExtensionKeys.battleHistory)
    }
}

private var todayString: String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt.string(from: Date())
}

private var sharedDefaults: UserDefaults {
    UserDefaults(suiteName: sharedSuiteName)!
}

// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        let today     = todayString
        let lastReset = sharedDefaults.string(forKey: ExtensionKeys.lastResetDate) ?? ""

        guard today != lastReset else {
            print("Interval started: \(activity.rawValue) — same day as last reset, skipping count reset")
            return
        }

        // This is a genuine new-day rollover. Save yesterday's result BEFORE
        // resetting counts so the result page has the right numbers.
        // Only do it once (on the first of the two activities to fire).
        if activity.rawValue == "mindful.daily" {
            saveYesterdayResult(using: sharedDefaults)
        }

        switch activity.rawValue {
        case "mindful.daily":
            sharedDefaults.set(0, forKey: ExtensionKeys.thresholdCount)
            sharedDefaults.set(today, forKey: ExtensionKeys.lastResetDate)
            print("Interval started: mindful.daily — friend count reset to 0 (new day: \(today))")
        case "foul.daily":
            sharedDefaults.set(0, forKey: ExtensionKeys.foulThresholdCount)
            print("Interval started: foul.daily — foul count reset to 0 (new day: \(today))")
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
            let current = sharedDefaults.integer(forKey: ExtensionKeys.foulThresholdCount)
            if count > current {
                sharedDefaults.set(count, forKey: ExtensionKeys.foulThresholdCount)
            }
            print("Foul milestone reached — \(raw), foul count = \(count), current = \(current)")
        } else if raw.hasPrefix("milestone_") {
            let count = Int(raw.split(separator: "_").last ?? "0") ?? 0
            let current = sharedDefaults.integer(forKey: ExtensionKeys.thresholdCount)
            if count > current {
                sharedDefaults.set(count, forKey: ExtensionKeys.thresholdCount)
            }
            print("Friend milestone reached — \(raw), friend count = \(count), current = \(current)")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
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
