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

struct LockedChapter: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let placeholderCount: Int
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
        Achievement(
            id: "bagDown",
            unlockedAsset: "stickerBagDown",
            lockedAsset:   "stickerBagDownSilhouette",
            title:         "15 wins, bag down",
            isUnlocked: { store in
                store.allResults.values.filter { $0 == .catWon }.count >= 15
            }
        ),
    ]

    private let chapter1Subtitle = "I have been crumpled, discarded, and forgotten by all who walk this earth — all, save one. She alone sees my true form. She alone knows what must be done. And I confess: I do not intend to make it easy for her."

    private let chapter2: LockedChapter = LockedChapter(
        id: "chapter2",
        title: "chapter 2 · the spider",
        subtitle: "I have eight eyes, and with all eight I have watched empires rise and fall in the corners of this room. I did not ask to be noticed. And yet she found me — and declared me the greatest threat this household has ever known. Perhaps she is not entirely wrong.",
        placeholderCount: 4
    )

    // MARK: Body

    var body: some View {
        ZStack(alignment: .topLeading) {

            Color(red: 250/255, green: 246/255, blue: 238/255)
                .ignoresSafeArea()
            
            // ── Back button ───────────────────────────────────────────────
            VStack(alignment: .leading) {
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
                .padding(.leading, 8)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // ── Chapter 1 ─────────────────────────────────────────
                        chapterSection(
                            title: "chapter 1 · the plastic bag",
                            subtitle: chapter1Subtitle,
                            achievements: chapter1
                        )
                        
                        // ── Chapter 2 (locked) ────────────────────────────────
                        lockedChapterSection(chapter2)
                        
                        Spacer().frame(height: 40)
                    }
                }
            }
            
            GeometryReader { geo in
                let gradientHeight = geo.size.height * 0.1
                let fadeColor = Color(red: 0xFF / 255.0, green: 0xFD / 255.0, blue: 0xF7 / 255.0)

                VStack(spacing: 0) {
                    Spacer()

                    // Bottom fade
                    LinearGradient(
                        stops: [
                            .init(color: fadeColor.opacity(0), location: 0),
                            .init(color: fadeColor, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: gradientHeight)
                }
            }
            .ignoresSafeArea()
        }
        .tint(.primary)
    }

    // MARK: - Chapter section

    @ViewBuilder
    private func chapterSection(title: String, subtitle: String, achievements: [Achievement]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.appBody)
                    .foregroundStyle(.primary)

                Rectangle()
                    .fill(.primary.opacity(0.15))
                    .frame(height: 1)

                Text(subtitle)
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 20
            ) {
                ForEach(achievements) { achievement in
                    achievementCell(achievement)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Locked chapter section

    @ViewBuilder
    private func lockedChapterSection(_ chapter: LockedChapter) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(chapter.title)
                    .font(.appBody)
                    .foregroundStyle(.secondary)

                Rectangle()
                    .fill(.primary.opacity(0.10))
                    .frame(height: 1)

                Text(chapter.subtitle)
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 20
            ) {
                ForEach(0 ..< chapter.placeholderCount, id: \.self) { _ in
                    lockedPlaceholderCell()
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Locked placeholder cell

    @ViewBuilder
    private func lockedPlaceholderCell() -> some View {
        GeometryReader { geo in
            let circleSize = geo.size.width * 0.8

            VStack(spacing: geo.size.width * 0.09) {
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: circleSize, height: circleSize)

                Text("???")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(0.85, contentMode: .fit)
    }

    // MARK: - Achievement cell

    @ViewBuilder
    private func achievementCell(_ achievement: Achievement) -> some View {
        let unlocked = achievement.isUnlocked(HistoryStore.self)

        GeometryReader { geo in
            let circleSize  = geo.size.width * 0.8
            let stickerSize = circleSize * 0.5

            VStack(spacing: geo.size.width * 0.09) {
                ZStack {
                    Circle()
                        .fill(unlocked ? Color.white : Color.clear)
                        .frame(width: circleSize, height: circleSize)
                        .shadow(color: .black.opacity(unlocked ? 0.08 : 0), radius: 6, y: 2)
                        .overlay {
                            if !unlocked {
                                Circle()
                                    .strokeBorder(
                                        style: StrokeStyle(
                                            lineWidth: 1.5,
                                            dash: [5, 4]
                                        )
                                    )
                                    .foregroundStyle(.secondary.opacity(0.5))
                            }
                        }

                    Image(unlocked ? achievement.unlockedAsset : achievement.lockedAsset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: stickerSize, height: stickerSize)
                        .opacity(unlocked ? 1.0 : 0.35)
                }

                Text(achievement.title)
                    .font(.appCaption)
                    .fontWeight(unlocked ? .bold : .regular)
                    .foregroundStyle(unlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(0.85, contentMode: .fit)
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
