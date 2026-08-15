//
//  DebugStoreView.swift
//  mindful3
//
//  A developer-only screen that surfaces the raw contents of SharedStore's
//  UserDefaults suite so you can confirm what the monitor extension has
//  written without attaching a debugger.
//
//  Usage — drop a sheet or NavigationLink somewhere convenient, e.g. in
//  MainPageView hold a secret tap gesture:
//
//      .onLongPressGesture { showDebug = true }
//      .sheet(isPresented: $showDebug) { DebugStoreView() }
//

import SwiftUI

struct DebugStoreView: View {

    // Re-read everything whenever the view appears or the user taps refresh.
    @State private var snapshot = StoreSnapshot()
    @State private var showCopied = false

    var body: some View {
        NavigationStack {
            List {

                // ── Live counters ──────────────────────────────────────────
                Section("Live counters (today)") {
                    kv("friend threshold count", "\(snapshot.friendCount)")
                    kv("foe threshold count",    "\(snapshot.foeCount)")
                    kv("is monitoring",          snapshot.isMonitoring ? "✅ yes" : "❌ no")
                }

                // ── Battle history ─────────────────────────────────────────
                Section("Battle history (\(snapshot.history.count) days)") {
                    if snapshot.history.isEmpty {
                        Text("No results saved yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(snapshot.history.keys.sorted().reversed(), id: \.self) { date in
                            HStack {
                                Text(date)
                                    .font(.system(.body, design: .monospaced))
                                Spacer()
                                resultBadge(snapshot.history[date] ?? "?")
                            }
                        }
                    }
                }

                // ── Minute totals ──────────────────────────────────────────
                Section("Minute totals (\(snapshot.minutes.count) days)") {
                    if snapshot.minutes.isEmpty {
                        Text("No minute data saved yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(snapshot.minutes.keys.sorted().reversed(), id: \.self) { date in
                            let m = snapshot.minutes[date]!
                            VStack(alignment: .leading, spacing: 2) {
                                Text(date)
                                    .font(.system(.body, design: .monospaced))
                                HStack(spacing: 16) {
                                    Label("\(m.friendMinutes) min", systemImage: "cat.fill")
                                        .foregroundStyle(.cyan)
                                    Label("\(m.foeMinutes) min", systemImage: "bag.fill")
                                        .foregroundStyle(.orange)
                                }
                                .font(.caption)
                            }
                        }
                    }
                }

                // ── Extension event log ────────────────────────────────────
                Section("Extension event log (\(snapshot.extensionLog.count) entries)") {
                    if snapshot.extensionLog.isEmpty {
                        Text("No events recorded yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(snapshot.extensionLog.reversed(), id: \.self) { entry in
                            Text(entry)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                    }
                }

                // ── Raw JSON ───────────────────────────────────────────────
                Section("Raw JSON") {
                    rawJSONBlock(key: "battleHistory",  data: snapshot.rawHistory)
                    rawJSONBlock(key: "battleMinutes",  data: snapshot.rawMinutes)
                }

                // ── Danger zone ────────────────────────────────────────────
                Section {
                    Button(role: .destructive) {
                        snapshot.injectFakeDay()
                        refresh()
                    } label: {
                        Label("Inject fake yesterday result (win)", systemImage: "wand.and.stars")
                    }

                    Button(role: .destructive) {
                        SharedStore.defaults.removeObject(forKey: "battleHistory")
                        SharedStore.defaults.removeObject(forKey: "battleMinutes")
                        refresh()
                    } label: {
                        Label("Clear all history", systemImage: "trash")
                    }

                    Button(role: .destructive) {
                        SharedStore.defaults.removeObject(forKey: "extensionDebugLog")
                        refresh()
                    } label: {
                        Label("Clear extension log", systemImage: "list.bullet.clipboard")
                    }
                } header: {
                    Text("Danger zone")
                }
            }
            .navigationTitle("Store Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh", systemImage: "arrow.clockwise") { refresh() }
                }
            }
            .onAppear { refresh() }
        }
    }

    // MARK: - Helpers

    private func refresh() {
        snapshot = StoreSnapshot()
    }

    @ViewBuilder
    private func kv(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder
    private func resultBadge(_ result: String) -> some View {
        let (label, tint): (String, Color) = switch result {
            case "win":  ("WIN",  .green)
            case "loss": ("LOSS", .red)
            default:     ("DRAW", .yellow)
        }
        Text(label)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.15), in: Capsule())
            .overlay(Capsule().strokeBorder(tint.opacity(0.4), lineWidth: 0.5))
    }

    @ViewBuilder
    private func rawJSONBlock(key: String, data: Data?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(key)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)

            if let data, let pretty = prettyJSON(data) {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(pretty)
                        .font(.system(size: 10, design: .monospaced))
                        .textSelection(.enabled)
                }
            } else {
                Text("(empty)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func prettyJSON(_ data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
        else { return nil }
        return String(decoding: pretty, as: UTF8.self)
    }
}

// MARK: - StoreSnapshot

/// Lightweight value type that captures the current defaults state.
private struct StoreSnapshot {

    struct MinuteRecord {
        let friendMinutes: Int
        let foeMinutes: Int
    }

    let friendCount:  Int
    let foeCount:     Int
    let isMonitoring: Bool
    let history:      [String: String]          // date → "win" / "loss" / "draw"
    let minutes:      [String: MinuteRecord]
    let rawHistory:   Data?
    let rawMinutes:   Data?
    let extensionLog: [String]

    init() {
        let d = SharedStore.defaults
        friendCount  = d.integer(forKey: "thresholdCount")
        foeCount     = d.integer(forKey: "foeThresholdCount")
        isMonitoring = d.bool(forKey: "isMonitoring")
        rawHistory   = d.data(forKey: "battleHistory")
        rawMinutes   = d.data(forKey: "battleMinutes")
        extensionLog = d.stringArray(forKey: "extensionDebugLog") ?? []

        // Decode history
        if let data = rawHistory,
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            history = decoded
        } else {
            history = [:]
        }

        // Decode minutes
        struct _DayMinutes: Codable {
            let friendMinutes: Int
            let foeMinutes: Int
        }
        if let data = rawMinutes,
           let decoded = try? JSONDecoder().decode([String: _DayMinutes].self, from: data) {
            minutes = decoded.mapValues { MinuteRecord(friendMinutes: $0.friendMinutes, foeMinutes: $0.foeMinutes) }
        } else {
            minutes = [:]
        }
    }

    // MARK: - Test helpers

    /// Writes a fake "win" result for yesterday so you can verify the history
    /// logic without waiting until midnight.
    func injectFakeDay() {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let key = fmt.string(from: yesterday)

        let d = SharedStore.defaults

        // history
        var hist = history
        hist[key] = "win"
        if let encoded = try? JSONEncoder().encode(hist) {
            d.set(encoded, forKey: "battleHistory")
        }

        // minutes
        struct _DayMinutes: Codable { let friendMinutes, foeMinutes: Int }
        var mins: [String: _DayMinutes]
        if let data = d.data(forKey: "battleMinutes"),
           let existing = try? JSONDecoder().decode([String: _DayMinutes].self, from: data) {
            mins = existing
        } else {
            mins = [:]
        }
        mins[key] = _DayMinutes(friendMinutes: 60, foeMinutes: 30)
        if let encoded = try? JSONEncoder().encode(mins) {
            d.set(encoded, forKey: "battleMinutes")
        }
    }
}

// MARK: - Preview

#Preview {
    DebugStoreView()
}
