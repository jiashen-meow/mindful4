//
//  HistoryStore.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Persists daily duel results and computes streaks.
//  Stored as JSON in the shared UserDefaults suite so the monitor extension
//  can write results at midnight too.
//

import Foundation
import FamilyControls

enum HistoryStore {

    // MARK: - Storage keys

    private static let resultsKey    = "battleHistory"
    private static let minutesKey    = "battleMinutes"
    private static let selectionsKey = "battleSelections"

    // MARK: - Result type

    enum DayResult: String, Codable {
        case catWon  = "win"
        case foeWon  = "loss"
        case draw    = "draw"
        /// Phone was off / extension suspended — no time data exists.
        /// Distinct from a 0:0 draw where both activities fired correctly.
        case empty   = "empty"
    }

    // MARK: - Stored minutes record

    struct DayMinutes: Codable {
        var friendMinutes: Int
        var foeMinutes:   Int
    }

    // MARK: - Stored selections record

    struct DaySelections: Codable {
        var friendSelection: FamilyActivitySelection
        var foeSelection:   FamilyActivitySelection
    }

    // MARK: - Read / Write (results)

    /// All stored results as a date-string → result dictionary.
    static var allResults: [String: DayResult] {
        get {
            guard let data = SharedStore.defaults.data(forKey: resultsKey),
                  let raw  = try? JSONDecoder().decode([String: String].self, from: data)
            else { return [:] }
            var out: [String: DayResult] = [:]
            for (k, v) in raw {
                if let r = DayResult(rawValue: v) { out[k] = r }
            }
            return out
        }
        set {
            let raw = newValue.mapValues { $0.rawValue }
            if let data = try? JSONEncoder().encode(raw) {
                SharedStore.defaults.set(data, forKey: resultsKey)
            }
        }
    }

    /// All stored minute totals as a date-string → DayMinutes dictionary.
    private static var allMinutes: [String: DayMinutes] {
        get {
            guard let data = SharedStore.defaults.data(forKey: minutesKey),
                  let decoded = try? JSONDecoder().decode([String: DayMinutes].self, from: data)
            else { return [:] }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                SharedStore.defaults.set(data, forKey: minutesKey)
            }
        }
    }

    /// All stored selections as a date-string → DaySelections dictionary.
    private static var allSelections: [String: DaySelections] {
        get {
            guard let data = SharedStore.defaults.data(forKey: selectionsKey),
                  let decoded = try? JSONDecoder().decode([String: DaySelections].self, from: data)
            else { return [:] }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                SharedStore.defaults.set(data, forKey: selectionsKey)
            }
        }
    }

    /// Save a single day's result, minute totals, and app selections. Keyed by "yyyy-MM-dd".
    /// Do not call this for empty days — use `saveEmptyResult` instead.
    static func saveResult(_ outcome: BattleOutcome, for dateString: String,
                           friendMinutes: Int, foeMinutes: Int,
                           friendSelection: FamilyActivitySelection,
                           foeSelection:   FamilyActivitySelection) {
        var currentResults = allResults
        switch outcome {
        case .catWon:  currentResults[dateString] = .catWon
        case .foeWon:  currentResults[dateString] = .foeWon
        case .draw:    currentResults[dateString] = .draw
        case .empty:   break   // should never happen — use saveEmptyResult
        }
        allResults = currentResults

        var currentMinutes = allMinutes
        currentMinutes[dateString] = DayMinutes(friendMinutes: friendMinutes, foeMinutes: foeMinutes)
        allMinutes = currentMinutes

        var currentSelections = allSelections
        currentSelections[dateString] = DaySelections(friendSelection: friendSelection,
                                                      foeSelection:   foeSelection)
        allSelections = currentSelections
    }

    /// Save an empty placeholder for a day where the extension never ran.
    /// Only writes to `battleHistory` — no minutes or selections are recorded
    /// because no real data exists for this day.
    static func saveEmptyResult(for dateString: String) {
        var currentResults = allResults
        // Don't overwrite a real result if one already exists.
        guard currentResults[dateString] == nil else { return }
        currentResults[dateString] = .empty
        allResults = currentResults
    }

    /// Result for a specific date string, or nil if no battle that day.
    static func result(for dateString: String) -> DayResult? {
        allResults[dateString]
    }

    /// Minute totals for a specific date string, or nil if not recorded.
    static func minutes(for dateString: String) -> DayMinutes? {
        allMinutes[dateString]
    }

    /// App selections for a specific date string, or nil if not recorded.
    static func selections(for dateString: String) -> DaySelections? {
        allSelections[dateString]
    }

    // MARK: - Streak

    /// Number of consecutive cat-win days ending on (and including) yesterday.
    static var currentWinStreak: Int {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        let results = allResults
        var streak  = 0
        var date    = Calendar.current.date(byAdding: .day, value: -1, to: Date())!

        while true {
            let key = fmt.string(from: date)
            guard results[key] == .catWon else { break }
            streak += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return streak
    }

    // MARK: - Calendar helpers

    /// All dates (as "yyyy-MM-dd") in a given month where the cat won.
    static func winDates(in year: Int, month: Int) -> Set<String> {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let results = allResults
        return Set(
            results
                .filter { $0.value == .catWon }
                .keys
                .filter {
                    guard let d = fmt.date(from: $0) else { return false }
                    let c = Calendar.current.dateComponents([.year, .month], from: d)
                    return c.year == year && c.month == month
                }
        )
    }
}
