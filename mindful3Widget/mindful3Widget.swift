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
    let foeCount: Int

    enum WidgetState { case winning, losing, draw }

    var widgetState: WidgetState {
        if friendCount > foeCount  { return .winning }
        if foeCount   > friendCount { return .losing  }
        return .draw
    }
}

// MARK: - Provider

struct MindfulProvider: TimelineProvider {

    private func currentEntry() -> MindfulEntry {
        let defaults = UserDefaults(suiteName: "group.jia.shen.crinkle")
            ?? UserDefaults.standard
        return MindfulEntry(
            date: .now,
            friendCount: defaults.integer(forKey: "thresholdCount"),
            foeCount:   defaults.integer(forKey: "foeThresholdCount")
        )
    }

    func placeholder(in context: Context) -> MindfulEntry {
        MindfulEntry(date: .now, friendCount: 4, foeCount: 2)
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

    @Environment(\.widgetFamily) private var widgetFamily

    private var imageAsset: String {
        switch widgetFamily {
        case .systemSmall:
            switch entry.widgetState {
            case .winning: return "widgetSmallWinning"
            case .losing:  return "widgetSmallLosing"
            case .draw:    return "widgetSmallDraw"
            }
        case .systemLarge:
            switch entry.widgetState {
            case .winning: return "widgetLargeWinning"
            case .losing:  return "widgetLargeLosing"
            case .draw:    return "widgetLargeDraw"
            }
        default: // .systemMedium
            switch entry.widgetState {
            case .winning: return "widgetMediumWinning"
            case .losing:  return "widgetMediumLosing"
            case .draw:    return "widgetMediumDraw"
            }
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
            Color(red: 0xFA / 255.0, green: 0xF6 / 255.0, blue: 0xEE / 255.0)
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
    MindfulEntry(date: .now, friendCount: 5, foeCount: 2) // winning
//    MindfulEntry(date: .now, friendCount: 1, foeCount: 6) // losing
//    MindfulEntry(date: .now, friendCount: 3, foeCount: 3) // draw
}
