//
//  DeviceActivityMonitorExtension.swift
//  MindfulActivityMonitor
//
//  Created by Jia Shen on 7/20/26.
//

import DeviceActivity
import Foundation
import WidgetKit

private let sharedSuiteName = "group.jia.shen.crinkle"

// Keys mirroring SharedStore.Keys — duplicated so the extension
// doesn't need to import the main app target.
// Suite name must match SharedStore.suiteName and the App Group entitlement in both targets.
private enum ExtensionKeys {
    static let thresholdCount     = "thresholdCount"
    static let foeThresholdCount  = "foeThresholdCount"
    static let battleHistory      = "battleHistory"
    static let battleMinutes      = "battleMinutes"
}

// MARK: - Midnight result persistence

/// Reads yesterday's counts and writes the battle result and minute totals
/// to their respective history dictionaries before the counts are reset.
/// Mirrors HistoryStore logic without importing the main target.
private func saveYesterdayResult(using defaults: UserDefaults) {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    // intervalDidEnd fires at 11:58 PM, so Date() is still the day being recorded.
    let yesterday = fmt.string(from: Date())

    // ── Load existing history ─────────────────────────────────────────────
    var history: [String: String]
    if let data = defaults.data(forKey: ExtensionKeys.battleHistory),
       let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
        history = decoded
    } else {
        history = [:]
    }

    // Idempotency guard: if a result for yesterday already exists, don't
    // overwrite it. snapshot.daily fires once per day so this shouldn't
    // normally trigger, but guards against edge cases (e.g. the user
    // restarting monitoring after 11:58 PM).
    guard history[yesterday] == nil else {
        print("saveYesterdayResult: result for \(yesterday) already saved, skipping")
        return
    }

    // Read both counts before either reset has happened.
    let friendCount = defaults.integer(forKey: ExtensionKeys.thresholdCount)
    let foeCount   = defaults.integer(forKey: ExtensionKeys.foeThresholdCount)

    print("saveYesterdayResult: friendCount=\(friendCount), foeCount=\(foeCount) for \(yesterday)")

    let result: String
    if friendCount > foeCount      { result = "win"  }
    else if foeCount > friendCount { result = "loss" }
    else                            { result = "draw" }

    // ── Persist result ────────────────────────────────────────────────────
    history[yesterday] = result
    if let encoded = try? JSONEncoder().encode(history) {
        defaults.set(encoded, forKey: ExtensionKeys.battleHistory)
    }

    // ── Persist minute totals ─────────────────────────────────────────────
    // Each threshold count represents one 15-minute milestone, so multiply by 15.
    struct DayMinutes: Codable {
        var friendMinutes: Int
        var foeMinutes:   Int
    }

    var minutes: [String: DayMinutes]
    if let data = defaults.data(forKey: ExtensionKeys.battleMinutes),
       let decoded = try? JSONDecoder().decode([String: DayMinutes].self, from: data) {
        minutes = decoded
    } else {
        minutes = [:]
    }
    minutes[yesterday] = DayMinutes(
        friendMinutes: friendCount * 15,
        foeMinutes:   foeCount   * 15
    )
    if let encoded = try? JSONEncoder().encode(minutes) {
        defaults.set(encoded, forKey: ExtensionKeys.battleMinutes)
    }
}

private var todayString: String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    fmt.timeZone = .current   // always use the device's local timezone
    return fmt.string(from: Date())
}

private var sharedDefaults: UserDefaults {
    UserDefaults(suiteName: sharedSuiteName)!
}

// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        let today  = todayString
        let name   = activity.rawValue

        guard name == "friend.daily" || name == "foe.daily" else { return }

        // ── Debug log ─────────────────────────────────────────────────────
        let ts     = ISO8601DateFormatter().string(from: Date())
        let logKey = "extensionDebugLog"
        var log    = sharedDefaults.stringArray(forKey: logKey) ?? []
        log.append("[\(ts)] intervalDidStart: \(name) (day: \(today))")
        if log.count > 20 { log = Array(log.suffix(20)) }
        sharedDefaults.set(log, forKey: logKey)

        switch name {
        case "friend.daily":
            sharedDefaults.set(0, forKey: ExtensionKeys.thresholdCount)
            print("intervalDidStart: friend.daily — friendCount reset to 0 (day: \(today))")
        case "foe.daily":
            sharedDefaults.set(0, forKey: ExtensionKeys.foeThresholdCount)
            print("intervalDidStart: foe.daily — foeCount reset to 0 (day: \(today))")
        default:
            break
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        // snapshot.daily ends at 11:58 PM — the sole authoritative place to
        // capture the day's result while counts are still intact.
        if activity.rawValue == "snapshot.daily" {
            saveYesterdayResult(using: sharedDefaults)

            // Append a timestamped entry to the debug log so Store Debug
            // confirms the extension is alive and fired at midnight.
            let ts = ISO8601DateFormatter().string(from: Date())
            let logKey = "extensionDebugLog"
            var log = sharedDefaults.stringArray(forKey: logKey) ?? []
            log.append("[\(ts)] intervalDidEnd: snapshot.daily")
            // Keep only the 20 most-recent entries so the array stays small.
            if log.count > 20 { log = Array(log.suffix(20)) }
            sharedDefaults.set(log, forKey: logKey)
        }
        print("Interval ended: \(activity.rawValue)")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        // Parse the milestone index out of the event name:
        //   "milestone_3"     → friend count = 3
        //   "foe_milestone_3" → foe count = 3
        //
        // Writing the index directly (not += 1) means delayed or out-of-order
        // delivery self-corrects on the very next milestone.
        let raw = event.rawValue

        if raw.hasPrefix("foe_milestone_") {
            let count   = Int(raw.split(separator: "_").last ?? "0") ?? 0
            let current = sharedDefaults.integer(forKey: ExtensionKeys.foeThresholdCount)
            if count > current {
                sharedDefaults.set(count, forKey: ExtensionKeys.foeThresholdCount)
            }
            print("foe milestone reached — \(raw), foe count = \(count), current = \(current)")
        } else if raw.hasPrefix("milestone_") {
            let count   = Int(raw.split(separator: "_").last ?? "0") ?? 0
            let current = sharedDefaults.integer(forKey: ExtensionKeys.thresholdCount)
            if count > current {
                sharedDefaults.set(count, forKey: ExtensionKeys.thresholdCount)
            }
            print("friend milestone reached — \(raw), friend count = \(count), current = \(current)")
        }

        WidgetCenter.shared.reloadAllTimelines()

        // Signal the main app (a separate process) that new counts are ready.
        // UserDefaults.didChangeNotification doesn't cross process boundaries,
        // but Darwin notifications do.
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("group.jia.shen.crinkle.countersDidChange" as CFString),
            nil, nil, true
        )
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
