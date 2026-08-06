//
//  AppState.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Single source of truth for navigation and battle state.
//  Passed through the environment from ContentView down to all child views.
//

import SwiftUI
import FamilyControls
import DeviceActivity

// MARK: - App flow pages

enum AppPage {
    /// Blank "tap to pick" slots — no selections yet, or user tapped "app selection" tab.
    case selection
    /// Review page: shows chosen app icons, "tap to change".
    case selected
    /// Ghost vs cat explainer before first battle.
    case confirmation
    /// Live battle view.
    case main
    /// Post-midnight result screen.
    case result
    /// Monthly calendar of past results.
    case history
    /// Achievement sticker book.
    case achievements
}

// MARK: - Battle outcome

enum BattleOutcome {
    case catWon
    case foulWon
    case draw
}

// MARK: - AppState

@Observable
final class AppState {

    // MARK: Navigation

    var currentPage: AppPage = .selection
    /// When the user is on selection/selected/confirmation pages during an active
    /// battle, show "← go back to main page" so they can bail without reselecting.
    var hasActiveBattle: Bool = false

    // MARK: Selections

    var friendSelection: FamilyActivitySelection = FamilyActivitySelection()
    var foulSelection:   FamilyActivitySelection = FamilyActivitySelection()

    var hasFriendSelection: Bool {
        !friendSelection.applicationTokens.isEmpty || !friendSelection.categoryTokens.isEmpty
    }

    var hasFoulSelection: Bool {
        !foulSelection.applicationTokens.isEmpty || !foulSelection.categoryTokens.isEmpty
    }

    var bothSelected: Bool { hasFriendSelection && hasFoulSelection }

    // MARK: Live counters (written by DeviceActivityMonitor extension)

    var friendCount: Int = 0   // milestones × 15 min
    var foulCount:   Int = 0

    var friendMinutes: Int { friendCount * 15 }
    var foulMinutes:   Int { foulCount   * 15 }

    // MARK: Result page data (set before navigating to .result)

    var pendingOutcome:       BattleOutcome = .draw
    var pendingFriendMinutes: Int = 0
    var pendingFoulMinutes:   Int = 0

    // MARK: - Initialiser

    init() {
        reload()
    }

    // MARK: - Public interface

    /// Called on every app foreground / appear. Syncs counters from the shared
    /// container and decides which page to show first.
    func reload() {
        SharedStore.defaults.synchronize()

        // Restore saved selections.
        if let s = SharedStore.loadFriendSelection() { friendSelection = s }
        if let s = SharedStore.loadFoulSelection()   { foulSelection   = s }

        friendCount = SharedStore.thresholdCount
        foulCount   = SharedStore.foulThresholdCount

        hasActiveBattle = SharedStore.isMonitoring

        // Check whether a completed duel is waiting to be shown.
        if SharedStore.isMonitoring && needsResultPage {
            prepareResult()
            currentPage = .result
            return
        }

        // Otherwise restore the right page.
        if SharedStore.isMonitoring {
            currentPage = .main
        } else if bothSelected {
            currentPage = .selected
        } else {
            currentPage = .selection
        }
    }

    /// Sync the live counters from UserDefaults (called on foreground / UserDefaults change).
    func syncCounters() {
        SharedStore.defaults.synchronize()
        let newFriend = SharedStore.thresholdCount
        let newFoul   = SharedStore.foulThresholdCount
        if newFriend != friendCount { friendCount = newFriend }
        if newFoul   != foulCount   { foulCount   = newFoul   }
    }

    // MARK: - Result page helpers

    /// True when `lastResetDate` is earlier than today and there has been at
    /// least one completed battle day.
    private var needsResultPage: Bool {
        let last = SharedStore.lastResetDate
        guard !last.isEmpty else { return false }
        return last < SharedStore.todayString
    }

    private func prepareResult() {
        // The counts still in SharedStore are yesterday's final values.
        pendingFriendMinutes = SharedStore.thresholdCount     * 15
        pendingFoulMinutes   = SharedStore.foulThresholdCount * 15

        if pendingFriendMinutes > pendingFoulMinutes {
            pendingOutcome = .catWon
        } else if pendingFoulMinutes > pendingFriendMinutes {
            pendingOutcome = .foulWon
        } else {
            pendingOutcome = .draw
        }
    }

    /// Called by ResultPageView when the user taps the CTA.
    /// Saves result to history, resets counters for the new day, and
    /// transitions to the main battle page.
    func acknowledgeResult() {
        // Save to history using yesterday's date.
        let yesterday = SharedStore.yesterdayString
        HistoryStore.saveResult(pendingOutcome, for: yesterday)

        // Reset counters for the new day.
        SharedStore.resetThresholdCount()
        SharedStore.resetFoulThresholdCount()
        SharedStore.lastResetDate = SharedStore.todayString

        friendCount = 0
        foulCount   = 0

        currentPage = .main
    }

    // MARK: - Navigation helpers

    func startBattle() {
        startMonitoring()
        hasActiveBattle = true
        currentPage = .main
    }

    func goToSelection() {
        currentPage = .selection
    }

    func resetBattle() {
        friendSelection = FamilyActivitySelection()
        foulSelection   = FamilyActivitySelection()
        SharedStore.removeFriendSelection()
        SharedStore.removeFoulSelection()
        SharedStore.resetThresholdCount()
        SharedStore.resetFoulThresholdCount()
        SharedStore.lastResetDate = ""
        SharedStore.isMonitoring  = false
        DeviceActivityCenter().stopMonitoring()
        friendCount     = 0
        foulCount       = 0
        hasActiveBattle = false
        currentPage     = .selection
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        guard !SharedStore.isMonitoring else { return }

        let center         = DeviceActivityCenter()
        let friendActivity = DeviceActivityName("mindful.daily")
        let foulActivity   = DeviceActivityName("foul.daily")

        center.stopMonitoring([friendActivity, foulActivity])

        SharedStore.saveFriendSelection(friendSelection)
        SharedStore.saveFoulSelection(foulSelection)

        let stepMinutes   = 15
        let maxMilestones = 8   // 8 × 15 min = 2 hours

        let dailySchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd:   DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        var friendEvents: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for i in 1...maxMilestones {
            friendEvents[DeviceActivityEvent.Name("milestone_\(i)")] = DeviceActivityEvent(
                applications:        friendSelection.applicationTokens,
                categories:          friendSelection.categoryTokens,
                webDomains:          friendSelection.webDomainTokens,
                threshold:           DateComponents(minute: i * stepMinutes),
                includesPastActivity: true
            )
        }

        var foulEvents: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for i in 1...maxMilestones {
            foulEvents[DeviceActivityEvent.Name("foul_milestone_\(i)")] = DeviceActivityEvent(
                applications:        foulSelection.applicationTokens,
                categories:          foulSelection.categoryTokens,
                webDomains:          foulSelection.webDomainTokens,
                threshold:           DateComponents(minute: i * stepMinutes),
                includesPastActivity: true
            )
        }

        do {
            if hasFriendSelection {
                try center.startMonitoring(friendActivity, during: dailySchedule, events: friendEvents)
            }
            if hasFoulSelection {
                try center.startMonitoring(foulActivity, during: dailySchedule, events: foulEvents)
            }
            SharedStore.isMonitoring  = true
            SharedStore.lastResetDate = SharedStore.todayString
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
}
