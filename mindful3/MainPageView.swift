//
//  MainPageView.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Live battle screen. Background image and mascot state update based
//  on who's winning. Light / dark mode handled by the "background" asset.
//

import SwiftUI
import DeviceActivity
import FamilyControls
internal import Combine
internal import ManagedSettings

struct MainPageView: View {

    @Environment(AppState.self) private var state

    // Sheet states
    @State private var showingFriendReport = false
    @State private var showingFoulReport   = false
    @State private var friendReportFilter: DeviceActivityFilter? = nil
    @State private var foulReportFilter:   DeviceActivityFilter? = nil

    // MARK: - Computed helpers

    private var battleState: BattleState {
        if state.friendCount > state.foulCount  { return .catWinning }
        if state.foulCount   > state.friendCount { return .foulWinning }
        return .draw
    }

    private enum BattleState { case catWinning, foulWinning, draw }

    private var foulMascotAsset: String {
        switch battleState {
        case .catWinning:  return "bag-unhappy"
        case .foulWinning: return "bag-happy"
        case .draw:        return "bag-happy"
        }
    }

    private var catMascotAsset: String {
        switch battleState {
        case .catWinning:  return "cat-proud"
        case .foulWinning: return "cat-frightened"
        case .draw:        return "cat-idle"
        }
    }

    private var foulSpeech: String {
        switch battleState {
        case .catWinning:  return "oh noooo... oh noooo \noh no no no..."
        case .foulWinning: return "heh... game over for you, caaaaat"
        case .draw:        return "tsk tsk...\nI'm gonna winnn !!!"
        }
    }

    private var catSpeech: String {
        switch battleState {
        case .catWinning:  return "Leave him to me, \njust keep it up!"
        case .foulWinning: return "I need more time, \nopen friend apps?"
        case .draw:        return "it's a draw, HELP !!!"
        }
    }

    private var segmentInterval: DeviceActivityFilter.SegmentInterval {
        .daily(during: Calendar.current.dateInterval(of: .day, for: .now)!)
    }

    private var friendFilter: DeviceActivityFilter {
        DeviceActivityFilter(
            segment:      segmentInterval,
            applications: Set(state.friendSelection.applicationTokens),
            categories:   Set(state.friendSelection.categoryTokens),
            webDomains:   Set(state.friendSelection.webDomainTokens)
        )
    }

    private var foulFilter: DeviceActivityFilter {
        DeviceActivityFilter(
            segment:      segmentInterval,
            applications: Set(state.foulSelection.applicationTokens),
            categories:   Set(state.foulSelection.categoryTokens),
            webDomains:   Set(state.foulSelection.webDomainTokens)
        )
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { screen in
            let w = screen.size.width
            let h = screen.size.height

            ZStack {
                // ── Base background color ──────────────────────────────────────
                Color(red: 0xF6 / 255.0, green: 0xF5 / 255.0, blue: 0xF1 / 255.0)
                    .ignoresSafeArea()

                // ── Background image (light / dark via asset catalog) ──────────
                Image("background")
                    .resizable()
                    .scaledToFit()

                // ── Top gradient overlay ──────────────────────────────────────
                VStack(spacing: 0) {
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0xFF / 255.0, green: 0xFD / 255.0, blue: 0xF7 / 255.0), location: 0),
                            .init(color: Color(red: 0xFF / 255.0, green: 0xFD / 255.0, blue: 0xF7 / 255.0).opacity(0), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: h * 0.3)
                    Spacer()
                }
                .ignoresSafeArea()

                // ── Bottom gradient overlay ────────────────────────────────────
                VStack(spacing: 0) {
                    Spacer()
                    LinearGradient(
                        stops: [
                            .init(color: Color(red: 0xFF / 255.0, green: 0xFD / 255.0, blue: 0xF7 / 255.0).opacity(0), location: 0),
                            .init(color: Color(red: 0xFF / 255.0, green: 0xFD / 255.0, blue: 0xF7 / 255.0), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: h * 0.10)
                }
                .ignoresSafeArea()

                // ── All content ───────────────────────────────────────────────
                VStack(spacing: 0) {

                    Spacer()
                    
                    topBar

                    Spacer()
                    Spacer()

                    HStack(alignment: .bottom) {
                        foulBlock(w: w)
                        Spacer()
                    }
                    .padding(.horizontal, w * 0.1)
                    
                    Spacer()

                    HStack(alignment: .bottom) {
                        Spacer()
                        catBlock(w: w)
                    }
                    .padding(.horizontal, w * 0.1)

                    Spacer()

                    bottomTabBar
                }
            }
        }
        // ── Counter sync ──────────────────────────────────────────────────
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            state.syncCounters()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UserDefaults.didChangeNotification,
            object: SharedStore.defaults)
        ) { _ in
            state.syncCounters()
        }
    }

    // MARK: - Sub-views

    /// Two-line top bar: date on one line, subtitle on the next.
    private var topBar: some View {
        VStack(spacing: 2) {
            Text(formattedToday)
                .font(.appHeadline)
                .foregroundStyle(.primary)
            Text("duel ends midnight · best-fed wins")
                .font(.appCaption)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }

    /// Foul (bag) mascot + name label + HP bar, left-aligned.
    private func foulBlock(w: CGFloat) -> some View {
        let mascotW = w * 0.2
        let hpW     = w * 0.46

        return VStack(alignment: .leading, spacing: 0) {
            Text("plastic bag")
                .font(.appCaption)
                .foregroundStyle(.primary)

            appIconRow(tokens: state.foulSelection.applicationTokens, alignment: .leading)

            foulHPFrame(frameW: hpW)

            foulMascotView
                .frame(width: mascotW)
        }
    }

    /// Cat mascot + name label + HP bar, right-aligned.
    private func catBlock(w: CGFloat) -> some View {
        let mascotW = w * 0.4
        let hpW     = w * 0.46

        return VStack(alignment: .trailing, spacing: 0) {
            catMascotView
                .frame(width: mascotW)

            Text("quicato")
                .font(.appCaption)
                .foregroundStyle(.primary)

            appIconRow(tokens: state.friendSelection.applicationTokens, alignment: .trailing)

            catHPFrame(frameW: hpW)
        }
    }

    private enum RowAlignment { case leading, trailing }

    /// A compact row of app icons (up to 5) for a given set of application tokens.
    private func appIconRow(
        tokens: Set<ApplicationToken>,
        alignment: RowAlignment
    ) -> some View {
        let sorted = Array(tokens).prefix(5)
        return HStack(spacing: 4) {
            if alignment == .trailing { Spacer(minLength: 0) }
            ForEach(Array(sorted), id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            if alignment == .leading { Spacer(minLength: 0) }
        }
        .padding(.top, 2)
        .padding(.bottom, 6)
    }

    private var foulMascotView: some View {
        Image(foulMascotAsset)
            .resizable()
            .scaledToFit()
    }

    private var catMascotView: some View {
        Image(catMascotAsset)
            .resizable()
            .scaledToFit()
    }

    /// Foul HP frame — HP bar image + "fed Xm" label below.
    private func foulHPFrame(frameW: CGFloat) -> some View {
        let frameH = frameW * 0.147
        return VStack(alignment: .leading, spacing: 2) {
            Image("foulHP\(min(state.foulCount, 8))")
                .resizable()
                .scaledToFit()
                .frame(width: frameW, height: frameH)

            Text("fed \(formatMinutes(state.foulMinutes))")
                .font(.appCaption)
                .foregroundStyle(.primary)
        }
    }

    /// Cat HP frame — HP bar image + "fed Xm" label below.
    private func catHPFrame(frameW: CGFloat) -> some View {
        let frameH = frameW * 0.147
        return VStack(alignment: .trailing, spacing: 2) {
            Image("catHP\(min(state.friendCount, 8))")
                .resizable()
                .scaledToFit()
                .frame(width: frameW, height: frameH)

            Text("fed \(formatMinutes(state.friendMinutes))")
                .font(.appCaption)
                .foregroundStyle(.primary)
        }
    }

    private var bottomTabBar: some View {
        HStack(spacing: 32) {
            Button {
                state.currentPage = state.bothSelected ? .selected : .selection
            } label: {
                VStack(spacing: 4) {
                    Image("buttonAppSelection")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 36)
                    Text("app selection")
                        .font(.appCaption)
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            Button {
                state.currentPage = .history
            } label: {
                VStack(spacing: 4) {
                    Image("buttonHistory")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 36)
                    Text("history")
                        .font(.appCaption)
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            Button {
                state.currentPage = .achievements
            } label: {
                VStack(spacing: 4) {
                    Image("buttonAchievement")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 36)
                    Text("achievement")
                        .font(.appCaption)
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(height: 64)
    }

    // MARK: - Report sheet builder

    @ViewBuilder
    private func reportSheet(
        filter: DeviceActivityFilter?,
        context: DeviceActivityReport.Context
    ) -> some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(uiColor: .systemGray4))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            if let filter {
                DeviceActivityReport(context, filter: filter)
            }

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Helpers

    /// Formats a minute count as "Xh Ym" (omits hours when zero).
    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    private var formattedToday: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: Date())
    }
}


#Preview {
    MainPageView()
        .environment(AppState())
}
