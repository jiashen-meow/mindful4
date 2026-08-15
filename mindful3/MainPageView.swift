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
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Theme helpers

    /// Base / gradient color: #FFFDF7 in light mode, #1B120D in dark mode.
    private var themeColor: Color {
        colorScheme == .dark
            ? Color(red: 0x1B / 255.0, green: 0x12 / 255.0, blue: 0x0D / 255.0)
            : Color(red: 0xFF / 255.0, green: 0xFD / 255.0, blue: 0xF7 / 255.0)
    }

    /// Background fill: #F6F5F1 in light mode, #1B120D in dark mode.
    private var backgroundFill: Color {
        colorScheme == .dark
            ? Color(red: 0x1B / 255.0, green: 0x12 / 255.0, blue: 0x0D / 255.0)
            : Color(red: 0xF6 / 255.0, green: 0xF5 / 255.0, blue: 0xF1 / 255.0)
    }

    /// Bottom gradient color: #352723 in dark mode, matches themeColor in light mode.
    private var bottomGradientColor: Color {
        colorScheme == .dark
            ? Color(red: 0x35 / 255.0, green: 0x27 / 255.0, blue: 0x23 / 255.0)
            : themeColor
    }

    /// Background image name: "backgroundDark" in dark mode, "background" in light.
    private var backgroundImageName: String {
        colorScheme == .dark ? "backgroundDark" : "background"
    }

    // Sheet states
    @State private var showingFriendReport = false
    @State private var showingfoeReport   = false
    @State private var friendReportFilter: DeviceActivityFilter? = nil
    @State private var foeReportFilter:   DeviceActivityFilter? = nil
    @State private var showingDebugStore  = false

    // MARK: - Computed helpers

    private var battleState: BattleState {
        if state.friendCount > state.foeCount  { return .catWinning }
        if state.foeCount   > state.friendCount { return .foeWinning }
        return .draw
    }

    private enum BattleState { case catWinning, foeWinning, draw }

    private var foeMascotAsset: String {
        switch battleState {
        case .catWinning:  return "bag-unhappy"
        case .foeWinning: return "bag-happy"
        case .draw:        return "bag-happy"
        }
    }

    private var catMascotAsset: String {
        switch battleState {
        case .catWinning:  return "cat-proud"
        case .foeWinning: return "cat-frightened"
        case .draw:        return "cat-idle"
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

    private var foeFilter: DeviceActivityFilter {
        DeviceActivityFilter(
            segment:      segmentInterval,
            applications: Set(state.foeSelection.applicationTokens),
            categories:   Set(state.foeSelection.categoryTokens),
            webDomains:   Set(state.foeSelection.webDomainTokens)
        )
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { screen in
            let w = screen.size.width
            let h = screen.size.height

            ZStack {
                // ── Base background color ──────────────────────────────────────
                backgroundFill
                    .ignoresSafeArea()

                // ── Background image (light / dark via asset catalog) ──────────
                Image(backgroundImageName)
                    .resizable()
                    .scaledToFit()

                // ── Top gradient overlay ──────────────────────────────────────
                VStack(spacing: 0) {
                    LinearGradient(
                        stops: [
                            .init(color: themeColor, location: 0),
                            .init(color: themeColor, location: 0.5),
                            .init(color: themeColor.opacity(0), location: 1)
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
                            .init(color: bottomGradientColor
                                .opacity(0), location: 0),
                            .init(color: bottomGradientColor
                                  ,
                                  location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: h * 0.3)
                }
                .ignoresSafeArea()

                // ── All content ───────────────────────────────────────────────
                VStack(spacing: 0) {

                    Spacer()
                    
                    topBar

                    Spacer()
                    Spacer()

                    HStack(alignment: .bottom) {
                        foeBlock(w: w)
                        Spacer()
                    }
                    .padding(.horizontal, w * 0.1)

                    Spacer()
                    Spacer()
                    
                    HStack(alignment: .bottom) {
                        Spacer()
                        catBlock(w: w)
                    }
                    .padding(.horizontal, w * 0.1)

                    Spacer()

                    bottomTabBar
                    
                    Spacer()
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
    /// Long-press the date to open the debug store inspector.
    private var topBar: some View {
        VStack(spacing: 2) {
            Text(formattedToday)
                .appHeadline
                .foregroundStyle(.primary)
                .onLongPressGesture { showingDebugStore = true }
            Text("duel ends midnight · best-fed wins")
                .appCaption
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showingDebugStore) {
            DebugStoreView()
        }
    }

    /// foe (bag) mascot + name label + HP bar, left-aligned.
    private func foeBlock(w: CGFloat) -> some View {
        let mascotW = w * 0.2
        let hpW     = w * 0.46

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text("plastic bag")
                    .appCaption
                    .foregroundStyle(.primary)
//                debugCountBadge(SharedStore.foeThresholdCount, tint: .orange)
            }

            appIconRow(
                appTokens: state.foeSelection.applicationTokens,
                catTokens: state.foeSelection.categoryTokens,
                alignment: .leading
            )

            foeHPFrame(frameW: hpW)
                .padding(.top, 8)

            foeMascotView
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

            HStack(spacing: 4) {
//                debugCountBadge(SharedStore.thresholdCount, tint: .cyan)
                Text("caaat")
                    .appCaption
                    .foregroundStyle(.primary)
            }

            appIconRow(
                appTokens: state.friendSelection.applicationTokens,
                catTokens: state.friendSelection.categoryTokens,
                alignment: .trailing
            )

            catHPFrame(frameW: hpW)
                .padding(.top, 8)
        }
    }

    private enum RowAlignment { case leading, trailing }

    /// A compact row of app + category icons (up to 5 total) for a given selection.
    private func appIconRow(
        appTokens: Set<ApplicationToken>,
        catTokens: Set<ActivityCategoryToken>,
        alignment: RowAlignment
    ) -> some View {
        let iconSize: CGFloat = 24
        let maxIcons = 5
        let appSlice = Array(appTokens.prefix(maxIcons))
        let catSlice = Array(catTokens.prefix(max(0, maxIcons - appSlice.count)))

        return HStack(spacing: 4) {
            if alignment == .trailing { Spacer(minLength: 0) }
            ForEach(appSlice, id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .scaleEffect(iconSize / 30)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            ForEach(catSlice, id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .scaleEffect(iconSize / 35)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            if alignment == .leading { Spacer(minLength: 0) }
        }
        .padding(.top, 2)
//        .padding(.bottom, 6)
    }

    private var foeMascotView: some View {
        Image(foeMascotAsset)
            .resizable()
            .scaledToFit()
    }

    private var catMascotView: some View {
        Image(catMascotAsset)
            .resizable()
            .scaledToFit()
    }

    /// foe HP frame — HP bar image + "fed Xm" label below.
    private func foeHPFrame(frameW: CGFloat) -> some View {
        let frameH = frameW * 0.09
        let suffix = colorScheme == .dark ? "_dark" : ""
        return VStack(alignment: .leading, spacing: 0) {
            Image("foeHP\(min(state.foeCount, 8))\(suffix)")
                .resizable()
                .scaledToFit()
                .frame(width: frameW, height: frameH)

            Text("fed \(formatMinutes(state.foeMinutes))")
                .appLabel
                .foregroundStyle(.primary)
        }
    }

    /// Cat HP frame — HP bar image + "fed Xm" label below.
    private func catHPFrame(frameW: CGFloat) -> some View {
        let frameH = frameW * 0.09
        let suffix = colorScheme == .dark ? "_dark" : ""
        return VStack(alignment: .trailing, spacing: 0) {
            Image("catHP\(min(state.friendCount, 8))\(suffix)")
                .resizable()
                .scaledToFit()
                .frame(width: frameW, height: frameH)

            Text("fed \(formatMinutes(state.friendMinutes))")
                .appLabel
                .foregroundStyle(.primary)
        }
    }

    private var bottomTabBar: some View {
        HStack(spacing: 32) {
            Button {
                state.currentPage = .selection
            } label: {
                VStack(spacing: 4) {
                    Image(colorScheme == .dark ? "buttonAppSelectionDark" : "buttonAppSelection")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 36)
                    Text("app selection")
                        .appCaption
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            Button {
                state.currentPage = .history
            } label: {
                VStack(spacing: 4) {
                    Image(colorScheme == .dark ? "buttonHistoryDark" : "buttonHistory")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 36)
                    Text("history")
                        .appCaption
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)

            Button {
                state.currentPage = .achievements
            } label: {
                VStack(spacing: 4) {
                    Image(colorScheme == .dark ? "buttonAchievementDark" : "buttonAchievement")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 36)
                    Text("achievement")
                        .appCaption
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

    /// A tiny pill badge showing a raw threshold count — useful for debugging.
    @ViewBuilder
    private func debugCountBadge(_ count: Int, tint: Color) -> some View {
        Text("\(count)")
            .font(.system(size: 9, weight: .semibold, design: .monospaced))
            .foregroundStyle(tint)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(tint.opacity(0.15), in: Capsule())
            .overlay(Capsule().strokeBorder(tint.opacity(0.4), lineWidth: 0.5))
    }

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
