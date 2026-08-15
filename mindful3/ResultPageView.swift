//
//  ResultPageView.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Displays the outcome of a single duel as a sheet from the history calendar.
//  Shows the duel date, mascot, title, per-side app icons with time totals,
//  and a context-sensitive info message.
//

import SwiftUI

struct ResultPageView: View {

    // ── Inputs ────────────────────────────────────────────────────────────────
    let outcome:       BattleOutcome
    let friendMinutes: Int
    let foeMinutes:   Int
    /// "yyyy-MM-dd" string used to render the date header.
    let dateString:    String

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer().frame(height: 24)

                // ── Date header ───────────────────────────────────────────
                Text(dateHeaderText)
                    .appCaption
                    .foregroundStyle(.secondary)

                Spacer()

                // ── Mascot ────────────────────────────────────────────────
                Image(mascotAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)

                Spacer().frame(height: 20)

                // ── Title ─────────────────────────────────────────────────
                Text(titleText)
                    .appTitle
                    .foregroundStyle(.primary)

                Spacer().frame(height: 28)

                // ── App rows ──────────────────────────────────────────────
                VStack(spacing: 12) {
                    appRow(
                        label:     "friend apps",
                        minutes:   friendMinutes,
                        timeColor: friendTimeColor
                    )
                    appRow(
                        label:     "foe apps",
                        minutes:   foeMinutes,
                        timeColor: foeTimeColor
                    )
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 28)

                // ── Info box ──────────────────────────────────────────────
                infoBox
                    .padding(.horizontal, 32)

                Spacer()
            }
        }
    }

    // MARK: - Date header

    private var dateHeaderText: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let date = fmt.date(from: dateString) else { return dateString }
        let display = DateFormatter()
        display.dateFormat = "MMMM d"
        return "the midnight duel · \(display.string(from: date))"
    }

    // MARK: - Computed assets

    private var mascotAsset: String {
        switch outcome {
        case .catWon:  return "cat-proud"
        case .foeWon: return "cat-frightened"
        case .draw:    return "cat-speechless"
        }
    }

    private var titleText: String {
        switch outcome {
        case .catWon:  return "caaat wins!"
        case .foeWon: return "the foe wins…"
        case .draw:    return "it's a draw…"
        }
    }

    // Friend time is green when cat won, red when foe won, neutral on draw.
    private var friendTimeColor: Color {
        switch outcome {
        case .catWon:  return Color(red: 0.18, green: 0.62, blue: 0.35)   // green
        case .foeWon: return Color(red: 0.80, green: 0.22, blue: 0.22)   // red
        case .draw:    return .primary
        }
    }

    // foe time is red when cat won, green when foe won, neutral on draw.
    private var foeTimeColor: Color {
        switch outcome {
        case .catWon:  return Color(red: 0.80, green: 0.22, blue: 0.22)   // red
        case .foeWon: return Color(red: 0.18, green: 0.62, blue: 0.35)   // green
        case .draw:    return .primary
        }
    }

    // MARK: - App row

    @ViewBuilder
    private func appRow(
        label: String,
        minutes: Int,
        timeColor: Color
    ) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .appCaption
                .foregroundStyle(.primary)

            Spacer()

            // Time total, coloured by outcome.
            Text(formattedTime(minutes: minutes))
                .appHeadline
                .foregroundStyle(timeColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.primary.opacity(0.05))
        )
    }

    // MARK: - Info box

    @ViewBuilder
    private var infoBox: some View {
        let streak = HistoryStore.currentWinStreak
        infoBoxContent(streak: streak)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func infoBoxContent(streak: Int) -> some View {
        switch outcome {
        case .catWon:
            VStack(spacing: 4) {
                if streak > 0 {
                    Text("🔥 \(streak)-day win streak!")
                        .appBody
                        .foregroundStyle(.primary)
                    Text("keep it going tomorrow")
                        .appCaption
                        .foregroundStyle(.secondary)
                } else {
                    Text("first win of a new streak!")
                        .appBody
                        .foregroundStyle(.primary)
                    Text("keep it going tomorrow")
                        .appCaption
                        .foregroundStyle(.secondary)
                }
            }

        case .foeWon:
            VStack(spacing: 4) {
                Text("\"i'll do better tomorrow…\"")
                    .appBody
                    .foregroundStyle(.primary)
                Text("— caaat, probably")
                    .appCaption
                    .foregroundStyle(.secondary)
            }

        case .draw:
            VStack(spacing: 4) {
                if streak > 0 {
                    Text("streak survived: \(streak) day\(streak == 1 ? "" : "s")")
                        .appBody
                        .foregroundStyle(.primary)
                    Text("a draw keeps the streak alive")
                        .appCaption
                        .foregroundStyle(.secondary)
                } else {
                    Text("nobody won, nobody lost")
                        .appBody
                        .foregroundStyle(.primary)
                    Text("tomorrow is a fresh start")
                        .appCaption
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formattedTime(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

#Preview("Cat wins") {
    ResultPageView(
        outcome:       .catWon,
        friendMinutes: 105,
        foeMinutes:   15,
        dateString:    "2026-07-27"
    )
}

#Preview("foe wins") {
    ResultPageView(
        outcome:       .foeWon,
        friendMinutes: 15,
        foeMinutes:   60,
        dateString:    "2026-07-26"
    )
}

#Preview("Draw") {
    ResultPageView(
        outcome:       .draw,
        friendMinutes: 30,
        foeMinutes:   30,
        dateString:    "2026-07-25"
    )
}
