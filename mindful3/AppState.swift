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
    /// Selection / review screen — shown before a battle starts, or when the
    /// user taps "app selection" from the main page. The view handles both the
    /// empty-state (nothing selected yet) and the review-state (tap to change)
    /// in a single unified layout.
    case selection
    /// Live battle view.
    case main
    /// Monthly calendar of past results.
    case history
    /// Achievement sticker book.
    case achievements
}

// MARK: - Battle outcome

enum BattleOutcome {
    case catWon
    case foeWon
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
    var foeSelection:   FamilyActivitySelection = FamilyActivitySelection()

    var hasFriendSelection: Bool {
        !friendSelection.applicationTokens.isEmpty || !friendSelection.categoryTokens.isEmpty
    }

    var hasfoeSelection: Bool {
        !foeSelection.applicationTokens.isEmpty || !foeSelection.categoryTokens.isEmpty
    }

    var bothSelected: Bool { hasFriendSelection && hasfoeSelection }

    /// True when there is an active battle AND the user has altered at least
    /// one selection from the values that were committed when monitoring started.
    /// Compared by diffing the token sets against whatever SharedStore persisted
    /// at `startMonitoring()` time.
    var selectionChanged: Bool {
        guard hasActiveBattle else { return false }
        let savedFriend = SharedStore.loadFriendSelection() ?? FamilyActivitySelection()
        let savedfoe   = SharedStore.loadfoeSelection()   ?? FamilyActivitySelection()
        let friendDiffers = friendSelection.applicationTokens != savedFriend.applicationTokens
                         || friendSelection.categoryTokens    != savedFriend.categoryTokens
        let foeDiffers   = foeSelection.applicationTokens   != savedfoe.applicationTokens
                         || foeSelection.categoryTokens      != savedfoe.categoryTokens
        return friendDiffers || foeDiffers
    }

    // MARK: Live counters (written by DeviceActivityMonitor extension)

    var friendCount: Int = 0   // milestones × 15 min
    var foeCount:   Int = 0

    var friendMinutes: Int { friendCount * 15 }
    var foeMinutes:   Int { foeCount   * 15 }

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
        if let s = SharedStore.loadfoeSelection()   { foeSelection   = s }

        friendCount = SharedStore.thresholdCount
        foeCount   = SharedStore.foeThresholdCount

        hasActiveBattle = SharedStore.isMonitoring

        // Don't interrupt an in-progress setup flow.
        let setupPages: Set<AppPage> = [.selection]
        if setupPages.contains(currentPage) && !SharedStore.isMonitoring {
            return
        }

        // Otherwise restore the right page.
        if SharedStore.isMonitoring {
            currentPage = .main
        } else {
            currentPage = .selection
        }
    }

    /// Sync the live counters from UserDefaults (called on foreground / UserDefaults change).
    func syncCounters() {
        SharedStore.defaults.synchronize()
        let newFriend = SharedStore.thresholdCount
        let newfoe   = SharedStore.foeThresholdCount
        if newFriend != friendCount { friendCount = newFriend }
        if newfoe   != foeCount   { foeCount   = newfoe   }
    }

    // MARK: - Navigation helpers

    func startBattle() {
        startMonitoring()
        hasActiveBattle = true
        currentPage = .main
    }

    /// Stops the current session, resets today's counters, and restarts
    /// monitoring with the current (possibly changed) selections.
    /// Called when the user hits "continue" after changing selections
    /// mid-battle. Does NOT clear history or wipe the selections.
    func restartBattle() {
        let center           = DeviceActivityCenter()
        let friendActivity   = DeviceActivityName("friend.daily")
        let foeActivity      = DeviceActivityName("foe.daily")
        let snapshotActivity = DeviceActivityName("snapshot.daily")
        center.stopMonitoring([friendActivity, foeActivity, snapshotActivity])

        SharedStore.isMonitoring = false
        SharedStore.resetThresholdCount()
        SharedStore.resetfoeThresholdCount()
        friendCount = 0
        foeCount   = 0

        startMonitoring()
        hasActiveBattle = true
        currentPage = .main
    }

    func goToSelection() {
        currentPage = .selection
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        guard !SharedStore.isMonitoring else { return }

        let center           = DeviceActivityCenter()
        let friendActivity   = DeviceActivityName("friend.daily")
        let foeActivity      = DeviceActivityName("foe.daily")
        let snapshotActivity = DeviceActivityName("snapshot.daily")

        center.stopMonitoring([friendActivity, foeActivity, snapshotActivity])

        SharedStore.saveFriendSelection(friendSelection)
        SharedStore.savefoeSelection(foeSelection)

        let stepMinutes   = 15
        let maxMilestones = 8   // 8 × 15 min = 2 hours

        let dailySchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd:   DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // Fires intervalDidEnd at 11:58 PM every day — the sole place
        // where yesterday's battle result is snapshotted before midnight.
        let snapshotSchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd:   DateComponents(hour: 23, minute: 58),
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

        var foeEvents: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for i in 1...maxMilestones {
            foeEvents[DeviceActivityEvent.Name("foe_milestone_\(i)")] = DeviceActivityEvent(
                applications:        foeSelection.applicationTokens,
                categories:          foeSelection.categoryTokens,
                webDomains:          foeSelection.webDomainTokens,
                threshold:           DateComponents(minute: i * stepMinutes),
                includesPastActivity: true
            )
        }

        do {
            if hasFriendSelection {
                try center.startMonitoring(friendActivity, during: dailySchedule, events: friendEvents)
            }
            if hasfoeSelection {
                try center.startMonitoring(foeActivity, during: dailySchedule, events: foeEvents)
            }
            try center.startMonitoring(snapshotActivity, during: snapshotSchedule)
            SharedStore.isMonitoring = true
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
}
