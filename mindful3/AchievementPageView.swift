//
//  AchievementPageView.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Sticker book organized by chapters.
//  Locked achievements show a silhouette; unlocked show the full sticker.
//

import SwiftUI

// MARK: - Achievement model

struct Achievement: Identifiable {
    let id: String
    let unlockedAsset: String
    let lockedAsset: String
    let title: String
    let isUnlocked: (HistoryStore.Type) -> Bool
}

// MARK: - AchievementPageView

struct AchievementPageView: View {

    @Environment(AppState.self) private var state

    private let chapter1: [Achievement] = [
        Achievement(
            id: "firstWin",
            unlockedAsset: "stickerFirstWin",
            lockedAsset:   "stickerFirstWinSilhouette",
            title:         "first win",
            isUnlocked: { store in
                store.allResults.values.contains(.catWon)
            }
        ),
        Achievement(
            id: "bagDown",
            unlockedAsset: "stickerBagDown",
            lockedAsset:   "stickerBagDownSilhouette",
            title:         "15 wins, bag down",
            isUnlocked: { store in
                store.allResults.values.filter { $0 == .catWon }.count >= 15
            }
        ),
        Achievement(
            id: "streak3",
            unlockedAsset: "streak3",
            lockedAsset:   "streak3Locked",
            title:         "3-day streak",
            isUnlocked: { _ in
                HistoryStore.currentWinStreak >= 3
                    || AchievementPageView.maxHistoricalStreak >= 3
            }
        ),
        Achievement(
            id: "streak7",
            unlockedAsset: "streak7",
            lockedAsset:   "streak7Locked",
            title:         "7-day streak",
            isUnlocked: { _ in
                HistoryStore.currentWinStreak >= 7
                    || AchievementPageView.maxHistoricalStreak >= 7
            }
        ),
    ]

    private let chapter2Teaser = "something with too many legs is waiting… beat the bag to find out"

    // MARK: Body

    var body: some View {
        ZStack(alignment: .topLeading) {

            Color(red: 250/255, green: 246/255, blue: 238/255)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    Spacer().frame(height: 60)

                    // ── Chapter 1 ─────────────────────────────────────────
                    chapterSection(
                        title: "chapter 1 · the plastic bag",
                        achievements: chapter1
                    )

                    // ── Chapter 2 (teaser) ────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("chapter 2 · ???")
                            .font(.appHeadline)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 24)

                        Text(chapter2Teaser)
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)
                    }

                    Spacer().frame(height: 40)
                }
            }

            // ── Back button ───────────────────────────────────────────────
            Button {
                state.currentPage = .main
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("go back")
                        .font(.appCaption)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .padding(.top, 56)
            .padding(.leading, 8)
        }
    }

    // MARK: - Chapter section

    @ViewBuilder
    private func chapterSection(title: String, achievements: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.appHeadline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 24)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 20
            ) {
                ForEach(achievements) { achievement in
                    achievementCell(achievement)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Achievement cell

    @ViewBuilder
    private func achievementCell(_ achievement: Achievement) -> some View {
        let unlocked = achievement.isUnlocked(HistoryStore.self)

        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(unlocked ? Color.white : Color(white: 0.87))
                    .frame(width: 88, height: 88)
                    .shadow(color: .black.opacity(unlocked ? 0.08 : 0), radius: 6, y: 2)

                Image(unlocked ? achievement.unlockedAsset : achievement.lockedAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .opacity(unlocked ? 1.0 : 0.35)
            }

            Text(achievement.title)
                .font(.appCaption)
                .fontWeight(unlocked ? .bold : .regular)
                .foregroundStyle(unlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Max historical streak

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
}

#Preview {
    AchievementPageView()
        .environment(AppState())
}
