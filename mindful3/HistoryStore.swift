//
//  HistoryStore.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Persists daily duel results and computes streaks.
//  Stored as a JSON-encoded [String: String] in the shared UserDefaults suite
//  so the monitor extension can write results at midnight too.
//

import Foundation

enum HistoryStore {

    // MARK: - Storage key

    private static let resultsKey = "battleHistory"

    // MARK: - Result type

    enum DayResult: String, Codable {
        case catWon  = "win"
        case foulWon = "loss"
        case draw    = "draw"
    }

    // MARK: - Read / Write

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

    /// Save a single day's result. Keyed by "yyyy-MM-dd".
    static func saveResult(_ outcome: BattleOutcome, for dateString: String) {
        var current = allResults
        switch outcome {
        case .catWon:  current[dateString] = .catWon
        case .foulWon: current[dateString] = .foulWon
        case .draw:    current[dateString] = .draw
        }
        allResults = current
    }

    /// Result for a specific date string, or nil if no battle that day.
    static func result(for dateString: String) -> DayResult? {
        allResults[dateString]
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
