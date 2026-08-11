//
//  mindful3Widget.swift
//  mindful3Widget
//
//  Created by Jia Shen on 7/23/26.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct MindfulEntry: TimelineEntry {
    let date: Date
    let friendCount: Int
    let foulCount: Int

    enum WidgetState { case winning, losing, draw }

    var widgetState: WidgetState {
        if friendCount > foulCount  { return .winning }
        if foulCount   > friendCount { return .losing  }
        return .draw
    }
}

// MARK: - Provider

struct MindfulProvider: TimelineProvider {

    private func currentEntry() -> MindfulEntry {
        let defaults = UserDefaults(suiteName: "group.jia.shen.quicato")
            ?? UserDefaults.standard
        return MindfulEntry(
            date: .now,
            friendCount: defaults.integer(forKey: "thresholdCount"),
            foulCount:   defaults.integer(forKey: "foulThresholdCount")
        )
    }

    func placeholder(in context: Context) -> MindfulEntry {
        MindfulEntry(date: .now, friendCount: 4, foulCount: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (MindfulEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MindfulEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh every 15 minutes to stay in sync with DeviceActivity milestones
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Widget View

struct mindful3WidgetEntryView: View {
    var entry: MindfulEntry

    private var imageAsset: String {
        switch entry.widgetState {
        case .winning: return "widgetWinning"
        case .losing:  return "widgetLosing"
        case .draw:    return "widgetDraw"
        }
    }

    private var stateLabel: String {
        switch entry.widgetState {
        case .winning: return "Winning 🏆"
        case .losing:  return "Losing 😤"
        case .draw:    return "Draw 🤝"
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Image(imageAsset)
                    .resizable()
                    .scaledToFit()
            }
        }
        .containerBackground(for: .widget) {
            Color.white
        }
    }
}

// MARK: - Widget Definition

struct mindful3Widget: Widget {
    let kind: String = "mindful3Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MindfulProvider()) { entry in
            mindful3WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Mindful Battle")
        .description("See who's winning today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    mindful3Widget()
} timeline: {
    MindfulEntry(date: .now, friendCount: 5, foulCount: 2) // winning
//    MindfulEntry(date: .now, friendCount: 1, foulCount: 6) // losing
//    MindfulEntry(date: .now, friendCount: 3, foulCount: 3) // draw
}
