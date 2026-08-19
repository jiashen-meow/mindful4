//
//  AchievementPageView.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Record book — flat grid of achievements.
//  Locked achievements show the locked asset at low opacity with a dashed border.
//  Unlocked achievements show the full asset with a solid white circle.
//

import SwiftUI
import FamilyControls

// MARK: - Achievement model

struct Achievement: Identifiable {
    let id:             String
    let unlockedAsset:  String
    let lockedAsset:    String
    let title:          String
    let subtitle:       String
    let isUnlocked:     (HistoryStore.Type) -> Bool
}

// MARK: - AchievementPageView

struct AchievementPageView: View {

    @Environment(AppState.self) private var state

    // MARK: - Achievement definitions

    private var achievements: [Achievement] {[
        Achievement(
            id:            "courageous",
            unlockedAsset: "stickerFirstWin",
            lockedAsset:   "stickerFirstWinSilhouette",
            title:         "Courageous",
            subtitle:      "start a duel",
            isUnlocked: { store in
                store.allResults.values.contains(.catWon)
                || store.allResults.count > 0
            }
        ),
        Achievement(
            id:            "streak3",
            unlockedAsset: "streak3",
            lockedAsset:   "streak3Locked",
            title:         "Three nights",
            subtitle:      "Streak of 3",
            isUnlocked: { _ in
                HistoryStore.currentWinStreak >= 3
                    || AchievementPageView.maxHistoricalStreak >= 3
            }
        ),
        Achievement(
            id:            "streak7",
            unlockedAsset: "streak7",
            lockedAsset:   "streak7Locked",
            title:         "Seven nights",
            subtitle:      "Streak of 7",
            isUnlocked: { _ in
                HistoryStore.currentWinStreak >= 7
                    || AchievementPageView.maxHistoricalStreak >= 7
            }
        ),
        Achievement(
            id:            "bagBeaten",
            unlockedAsset: "stickerBagDown",
            lockedAsset:   "stickerBagDownSilhouette",
            title:         "Bag beaten",
            subtitle:      "15 duels won",
            isUnlocked: { store in
                store.allResults.values.filter { $0 == .catWon }.count >= 15
            }
        ),
        Achievement(
            id:            "untouched",
            unlockedAsset: "untouched",
            lockedAsset:   "untouchedLocked",
            title:         "Untouched",
            subtitle:      "Foe fed 0:00",
            isUnlocked: { store in
                store.allResults.keys.contains { dateStr in
                    guard let mins = store.minutes(for: dateStr) else { return false }
                    return mins.foeMinutes == 0
                        && store.result(for: dateStr) == .catWon
                }
            }
        ),
        Achievement(
            id:            "magnificent",
            unlockedAsset: "magnificent",
            lockedAsset:   "magnificentLocked",
            title:         "Magnificent",
            subtitle:      "Friend fed 2:00",
            isUnlocked: { store in
                store.allResults.keys.contains { dateStr in
                    guard let mins = store.minutes(for: dateStr) else { return false }
                    return mins.friendMinutes >= 120
                }
            }
        ),
        Achievement(
            id:            "newNemesis",
            unlockedAsset: "newNemesis",
            lockedAsset:   "newNemesisLocked",
            title:         "New nemesis",
            subtitle:      "a 2nd foe picked",
            isUnlocked: { store in
                AchievementPageView.hasPickedSecondFoe(store)
            }
        ),
        Achievement(
            id:            "landslide",
            unlockedAsset: "landslide",
            lockedAsset:   "landslideLocked",
            title:         "Landslide",
            subtitle:      "win by 1h 30m",
            isUnlocked: { store in
                store.allResults.keys.contains { dateStr in
                    guard let mins = store.minutes(for: dateStr),
                          store.result(for: dateStr) == .catWon else { return false }
                    return (mins.friendMinutes - mins.foeMinutes) >= 90
                }
            }
        ),
    ]}

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {

            Color.appBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {

                // ── Back button ───────────────────────────────────────────
                Button {
                    state.currentPage = .main
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("go back")
                            .appCaption
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .padding(.leading, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Header ────────────────────────────────────────
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("Record Book")
                                    .appTitle
                                    .foregroundStyle(.primary)
                                Spacer()
                                let unlockedCount = achievements.filter {
                                    $0.isUnlocked(HistoryStore.self)
                                }.count
                                let total = achievements.count
                                Text("\(unlockedCount) out of \(total) inked")
                                    .appCaption
                                    .foregroundStyle(.secondary)
                            }
                            Text("I keep count. Obviously I keep count.")
                                .appCaption
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 8)

                        // ── Achievement grid ──────────────────────────────
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ],
                            spacing: 24
                        ) {
                            ForEach(achievements) { achievement in
                                achievementCell(achievement)
                            }

                            // Coming soon placeholder
                            comingSoonCell()
                        }
                        .padding(.horizontal, 24)

                        Spacer().frame(height: 40)
                    }
                }
            }

            // ── Bottom fade ───────────────────────────────────────────────
            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(
                        stops: [
                            .init(color: Color.appBackground.opacity(0), location: 0),
                            .init(color: Color.appBackground,            location: 1)
                        ],
                        startPoint: .top,
                        endPoint:   .bottom
                    )
                    .frame(height: geo.size.height * 0.1)
                }
            }
            .ignoresSafeArea()
        }
        .tint(.primary)
    }

    // MARK: - Achievement cell

    @ViewBuilder
    private func achievementCell(_ achievement: Achievement) -> some View {
        let unlocked = achievement.isUnlocked(HistoryStore.self)

        GeometryReader { geo in
            let circleSize  = geo.size.width * 0.82
            let stickerSize = circleSize * 0.48

            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(unlocked ? Color.white : Color.clear)
                        .frame(width: circleSize, height: circleSize)
                        .shadow(color: .black.opacity(unlocked ? 0.08 : 0), radius: 6, y: 2)
                        .overlay {
                            if !unlocked {
                                Circle()
                                    .strokeBorder(
                                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                                    )
                                    .foregroundStyle(.secondary.opacity(0.4))
                            }
                        }

                    Image(unlocked ? achievement.unlockedAsset : achievement.lockedAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: stickerSize, height: stickerSize)
                        .opacity(unlocked ? 1.0 : 0.3)
                }
                .padding(.bottom, 18)
                .frame(width: circleSize, height: circleSize)

                Text(achievement.title)
                    .appCaption
                    .fontWeight(unlocked ? .semibold : .regular)
                    .foregroundStyle(unlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(achievement.subtitle)
                    .appCaption
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(0.75, contentMode: .fit)
    }

    // MARK: - Coming soon cell

    @ViewBuilder
    private func comingSoonCell() -> some View {
        GeometryReader { geo in
            let circleSize = geo.size.width * 0.82

            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: circleSize, height: circleSize)
                }
                .padding(.bottom, 18)
                .frame(width: circleSize, height: circleSize)

                Text("Coming soon")
                    .appCaption
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("you'll know")
                    .appCaption
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(0.75, contentMode: .fit)
    }

    // MARK: - Helpers

    /// Max consecutive cat-win streak across all of history.
    static var maxHistoricalStreak: Int {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let results = HistoryStore.allResults
        guard !results.isEmpty else { return 0 }

        let winDates = results
            .filter { $0.value == .catWon }
            .keys
            .compactMap { fmt.date(from: $0) }
            .sorted()

        var maxStreak = 0
        var current   = 0
        var prev: Date? = nil

        for date in winDates {
            if let p = prev,
               Calendar.current.dateComponents([.day], from: p, to: date).day == 1 {
                current += 1
            } else {
                current = 1
            }
            if current > maxStreak { maxStreak = current }
            prev = date
        }
        return maxStreak
    }

    /// True if the user has ever recorded a duel with a different foe selection
    /// than the first one saved in battleSelections.
    static func hasPickedSecondFoe(_ store: HistoryStore.Type) -> Bool {
        let allDates = store.allResults.keys.sorted()
        guard allDates.count >= 2 else { return false }
        guard let firstSel = store.selections(for: allDates[0]) else { return false }
        return allDates.dropFirst().contains { dateStr in
            guard let sel = store.selections(for: dateStr) else { return false }
            return sel.foeSelection.applicationTokens != firstSel.foeSelection.applicationTokens
                || sel.foeSelection.categoryTokens    != firstSel.foeSelection.categoryTokens
        }
    }
}

#Preview {
    AchievementPageView()
        .environment(AppState())
}
