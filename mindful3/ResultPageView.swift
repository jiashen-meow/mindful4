//
//  ResultPageView.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Shown once per day, the morning after a completed duel.
//  Displays outcome, time totals, and a context-sensitive info box.
//

import SwiftUI

struct ResultPageView: View {

    @Environment(AppState.self) private var state

    var body: some View {
        ZStack {
            Color(red: 250/255, green: 246/255, blue: 238/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // ── Mascot ────────────────────────────────────────────────
                Image(mascotAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)

                Spacer().frame(height: 24)

                // ── Title ─────────────────────────────────────────────────
                Text(titleText)
                    .font(.appTitle)
                    .foregroundStyle(.primary)

                Spacer().frame(height: 16)

                // ── Time totals ───────────────────────────────────────────
                HStack(spacing: 32) {
                    timeBlock(
                        icon: "bag-happy",
                        minutes: state.pendingFoulMinutes,
                        label: "plastic bag"
                    )
                    timeBlock(
                        icon: "cat-idle",
                        minutes: state.pendingFriendMinutes,
                        label: "caaat"
                    )
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 24)

                // ── Info box ──────────────────────────────────────────────
                infoBox
                    .padding(.horizontal, 32)

                Spacer().frame(height: 40)

                // ── CTA button ────────────────────────────────────────────
                Button {
                    state.acknowledgeResult()
                } label: {
                    Text(ctaText)
                        .font(.appCaption)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.primary.opacity(0.08))
                        )
                }

                Spacer()
            }
        }
    }

    // MARK: - Computed strings & assets

    private var mascotAsset: String {
        switch state.pendingOutcome {
        case .catWon:  return "cat-proud"
        case .foulWon: return "cat-frightened"
        case .draw:    return "cat-speechless"
        }
    }

    private var titleText: String {
        switch state.pendingOutcome {
        case .catWon:  return "caaat wins!"
        case .foulWon: return "the foul wins…"
        case .draw:    return "it's a draw…"
        }
    }

    private var ctaText: String {
        switch state.pendingOutcome {
        case .catWon:  return "see you today →"
        case .foulWon: return "avenge your caaat today →"
        case .draw:    return "settle it today →"
        }
    }

    // MARK: - Info box

    @ViewBuilder
    private var infoBox: some View {
        let streak = HistoryStore.currentWinStreak

        RoundedRectangle(cornerRadius: 16)
            .fill(Color.primary.opacity(0.06))
            .overlay(
                infoBoxContent(streak: streak)
                    .padding(16)
            )
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func infoBoxContent(streak: Int) -> some View {
        switch state.pendingOutcome {
        case .catWon:
            VStack(spacing: 4) {
                if streak > 0 {
                    Text("🔥 \(streak)-day win streak!")
                        .font(.appBody)
                        .foregroundStyle(.primary)
                    Text("keep it going tomorrow")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("first win of a new streak!")
                        .font(.appBody)
                        .foregroundStyle(.primary)
                    Text("keep it going tomorrow")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

        case .foulWon:
            VStack(spacing: 4) {
                Text("\"i'll do better tomorrow…\"")
                    .font(.appBody)
                    .foregroundStyle(.primary)
                Text("— caaat, probably")
                    .font(.appCaption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

        case .draw:
            VStack(spacing: 4) {
                if streak > 0 {
                    Text("streak survived: \(streak) day\(streak == 1 ? "" : "s")")
                        .font(.appBody)
                        .foregroundStyle(.primary)
                    Text("a draw keeps the streak alive")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("nobody won, nobody lost")
                        .font(.appBody)
                        .foregroundStyle(.primary)
                    Text("tomorrow is a fresh start")
                        .font(.appCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Time block helper

    private func timeBlock(icon: String, minutes: Int, label: String) -> some View {
        VStack(spacing: 6) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)

            Text(formattedTime(minutes: minutes))
                .font(.appHeadline)
                .foregroundStyle(.primary)

            Text(label)
                .font(.appCaption)
                .foregroundStyle(.secondary)
        }
    }

    private func formattedTime(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

#Preview {
    ResultPageView()
        .environment(AppState())
}
