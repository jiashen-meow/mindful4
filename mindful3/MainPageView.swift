//
//  MainPageView.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Live battle screen. Background, mascot state, and speech bubbles all
//  update based on who's winning and what time of day it is.
//

import SwiftUI
import DeviceActivity
import FamilyControls
internal import Combine

struct MainPageView: View {

    @Environment(AppState.self) private var state

    // Sheet states
    @State private var showingFriendReport = false
    @State private var showingFoulReport   = false
    @State private var friendReportFilter: DeviceActivityFilter? = nil
    @State private var foulReportFilter:   DeviceActivityFilter? = nil

    // Countdown timer
    @State private var secondsUntilMidnight: Int = Self.computeSecondsUntilMidnight()

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    // MARK: - Computed helpers

    private var battleState: BattleState {
        if state.friendCount > state.foulCount  { return .catWinning }
        if state.foulCount   > state.friendCount { return .foulWinning }
        return .draw
    }

    private enum BattleState { case catWinning, foulWinning, draw }

    private var backgroundAsset: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return "mainPageMorningBackground"
        case 12..<18: return "mainPageAfternoonBackground"
        default:      return "mainPageNightBackground"
        }
    }

    private var backgroundGradientColors: [Color] {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:   // Morning
            return [
                Color(red: 0xFB / 255.0, green: 0xF8 / 255.0, blue: 0xF1 / 255.0),
                Color(red: 0xD4 / 255.0, green: 0xC3 / 255.0, blue: 0xB0 / 255.0)
            ]
        case 12..<18:  // Afternoon
            return [
                Color(red: 0xFA / 255.0, green: 0xF6 / 255.0, blue: 0xEE / 255.0),
                Color(red: 0x9D / 255.0, green: 0x82 / 255.0, blue: 0x73 / 255.0)
            ]
        default:       // Evening / Night
            return [
                Color(red: 0xF8 / 255.0, green: 0xF1 / 255.0, blue: 0xE9 / 255.0),
                Color(red: 0x64 / 255.0, green: 0x61 / 255.0, blue: 0x66 / 255.0)
            ]
        }
    }

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
        case .catWinning:  return "nooo…"
        case .foulWinning: return "hehehe"
        case .draw:        return "…"
        }
    }

    private var catSpeech: String {
        switch battleState {
        case .catWinning:  return "let's goo!"
        case .foulWinning: return "help me…"
        case .draw:        return "mrrp"
        }
    }

    private var countdownText: String {
        let h = secondsUntilMidnight / 3600
        let m = (secondsUntilMidnight % 3600) / 60
        if h > 0 { return "duel in \(h)h \(m)m" }
        return "duel in \(m)m"
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
            let topReserve = screen.safeAreaInsets.top
            let botReserve = screen.safeAreaInsets.bottom
            
            ZStack {
                // ── Background gradient (extends into status bar) ─────────────
                LinearGradient(
                    colors: backgroundGradientColors,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // ── Background image ──────────────────────────────────────────
                Image(backgroundAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .mask(EdgeFadeMask(fade: 0.10))
                

                // … lay out only inside the safe area.
                GeometryReader { content in
                    // w/h are the full screen dimensions — (0,0) is top-left.
                    // All .position(x:y:) values below are screen-relative.
                    let totalH = content.size.height - topReserve - botReserve
                    let unit   = totalH / 15          // 1 row
                    let colW   = content.size.width / 3
                    let w      = content.size.width
                    let h      = content.size.height

                    ZStack(alignment: .topLeading) {

                        topBar
                            .frame(width: w, height: unit)
                            .position(x: w / 2, y: topReserve + unit / 2)

                        foulMascotView
                            .frame(width: w * 0.20)
                            .position(x: w * 0.33 , y: h * 0.43)

                        foulHPFrame(frameW: w * 0.50)
                            .position(x: w * 0.308, y: h * 0.35)

                        catMascotView
                            .frame(width: w * 0.25)
                            .position(x: w * 0.75 , y: h * 0.63)
                        
                        catHPFrame(frameW: w * 0.50)
                            .position(x: w * 0.70, y: h * 0.76)

                        bottomTabBar
                            .frame(width: w)
                            .position(x: w / 2, y: h * 0.92)
                    }
                    .frame(width: w, height: h)
                }
            }
        

            // NOTE: GeometryReader does NOT clip to the safe area — it fills
            // whatever space its parent offers. Because the parent ZStack
            // has .ignoresSafeArea() on the background image, content.size
            // here reflects the FULL screen, safe area included. The VStack
            // inside handles its own layout within that full extent.
        }
        // ── Friend report sheet ───────────────────────────────────────────
        .sheet(isPresented: $showingFriendReport) {
            reportSheet(filter: friendReportFilter, context: .friendAppActivity)
        }
        // ── Foul report sheet ─────────────────────────────────────────────
        .sheet(isPresented: $showingFoulReport) {
            reportSheet(filter: foulReportFilter, context: .foulAppActivity)
        }
        // ── Counter sync ──────────────────────────────────────────────────
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            state.syncCounters()
            secondsUntilMidnight = Self.computeSecondsUntilMidnight()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UserDefaults.didChangeNotification,
            object: SharedStore.defaults)
        ) { _ in
            state.syncCounters()
        }
        .onReceive(timer) { _ in
            secondsUntilMidnight = Self.computeSecondsUntilMidnight()
        }
    }

    // MARK: - Sub-views

    private var topBar: some View {
        DayArcView(
            formattedDate: formattedToday,
            countdownText: countdownText
        )
    }
    
    private var foulMascotView: some View {
        Image(foulMascotAsset)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                foulReportFilter = foulFilter
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showingFoulReport = true
                }
            }
    }

    private var catMascotView: some View {
        Image(catMascotAsset)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                friendReportFilter = friendFilter
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showingFriendReport = true
                }
            }
    }

    /// Foul HP frame — text label + HP image asset, no speech bubble.
    private func foulHPFrame(frameW: CGFloat) -> some View {
        let frameH = frameW * 0.147
        return HStack(spacing: frameW * 0.02) {
            Text("1h 15m")
                .font(.appCaption)

            Image("foulHP\(min(state.foulCount, 8))")
                .resizable()
                .scaledToFit()
                .frame(width: frameW * 0.77, height: frameH * 0.53)
        }
        .frame(width: frameW, height: frameH)
        .onTapGesture {
            foulReportFilter = foulFilter
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showingFoulReport = true
            }
        }
    }
    
    /// Cat HP frame — text label + HP image asset, no speech bubble.
    private func catHPFrame(frameW: CGFloat) -> some View {
        let frameH = frameW * 0.147
        return HStack(spacing: frameW * 0.02) {
            Image("catHP\(min(state.foulCount, 8))")
                .resizable()
                .scaledToFit()
                .frame(width: frameW * 0.77, height: frameH * 0.53)
            
            Text("12h 15m")
                .font(.appCaption)
        }
        .frame(width: frameW, height: frameH)
        .onTapGesture {
            foulReportFilter = foulFilter
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showingFoulReport = true
            }
        }
    }

    private var bottomTabBar: some View {
        HStack(spacing: 32) {
            Button {
                state.currentPage = .selection
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

    private var formattedToday: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: Date())
    }

    static func computeSecondsUntilMidnight() -> Int {
        let cal = Calendar.current
        let now = Date()
        guard let midnight = cal.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) else { return 0 }
        return max(0, Int(midnight.timeIntervalSince(now)))
    }
}

// MARK: - DayArcView

/// Draws a dashed parabolic arc spanning the full width.
/// The sun (before 18:00) or moon (18:00+) icon rides along the arc
/// based on the fraction of the day that has elapsed (midnight → midnight).
private struct DayArcView: View {

    let formattedDate: String
    let countdownText: String

    /// 0.0 = midnight (left end), 1.0 = next midnight (right end).
    private var dayProgress: Double {
        let now        = Date()
        let cal        = Calendar.current
        let startOfDay = cal.startOfDay(for: now)
        let elapsed    = now.timeIntervalSince(startOfDay)
        return min(max(elapsed / 86_400, 0), 1)
    }

    private var useSun: Bool {
        Calendar.current.component(.hour, from: Date()) < 18
    }

    var body: some View {
        GeometryReader { geo in
            arcContents(size: geo.size)
        }
    }

    private func arcContents(size: CGSize) -> some View {
        let w = size.width * 5/8
        let h = size.height

        // The view already lives inside the safe area, so we can use the
        // full height directly.
        // arcPeakY — y of the nadir of the ∪ arc (above the label strip)
        let arcPeakY = h                 // nadir sits near the bottom
        let arcDepth = arcPeakY

        func arcPoint(_ t: Double) -> CGPoint {
            let x = w * t
            // ∪ parabola: endpoints at arcEndY, nadir at arcPeakY
            let y = arcPeakY - 4 * arcDepth * t * (1 - t)
            return CGPoint(x: x, y: y)
        }

        let iconPt:   CGPoint  = arcPoint(dayProgress)
        let iconSize: CGFloat  = 44

        // All arc elements share the same (w × h) coordinate space so that
        // position(x:y:) values are consistent across the canvas, icon, and label.
        let arcContent = ZStack(alignment: .topLeading) {

            // ── Dashed arc ─────────────────────────────────────────
            Canvas { ctx, _ in
                var path = Path()
                path.move(to: arcPoint(0))
                stride(from: 0.02, through: 1.0, by: 0.02).forEach { t in
                    path.addLine(to: arcPoint(t))
                }
                ctx.stroke(
                    path,
                    with: .color(.primary.opacity(0.35)),
                    style: StrokeStyle(lineWidth: 1.2, dash: [4, 5])
                )
            }

            // ── Sun / moon icon riding the arc ─────────────────────
            Image(useSun ? "icon-sun" : "icon-moon")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .position(x: iconPt.x, y: iconPt.y)

            // ── Date • countdown label — at the nadir of the arc ───
            Text("\(formattedDate)  •  \(countdownText)")
                .font(.appCaption)
                .foregroundStyle(.primary)
                .frame(width: w, alignment: .center)
                .position(x: w / 2, y: arcPeakY)
        }
        .frame(width: w, height: h)

        return arcContent
            .frame(maxWidth: .infinity)  // expand to full row width …
            .frame(height: h)            // … while keeping the fixed height
    }
}

// MARK: - HealthBar

struct HealthBar: View {
    let label:    String    // e.g. "1h 15m"
    let progress: Double    // 0...1
    let color:    Color
    let width:    CGFloat   // pass in e.g. geo.size.width * 0.45

    var body: some View {
        HStack(spacing: width * 0.02) {
            Text(label)
                .font(.system(size: width * 0.20, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .fixedSize()

            SegmentedBar(progress: progress, color: color)
                .frame(width: width * 0.77, height: width * 0.53)
        }
        .frame(width: width)
    }
}

// MARK: - SegmentedBar

/// A row of 8 equal segments that fill from left to right based on `progress`.
private struct SegmentedBar: View {
    let progress: Double   // 0...1
    let color:    Color

    private let segments = 8

    var body: some View {
        GeometryReader { geo in
            let gap  = geo.size.width * 0.03
            let segW = (geo.size.width - gap * CGFloat(segments - 1)) / CGFloat(segments)
            let h    = geo.size.height

            HStack(spacing: gap) {
                ForEach(0..<segments, id: \.self) { i in
                    let threshold = Double(i + 1) / Double(segments)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(progress >= threshold ? color : color.opacity(0.2))
                        .frame(width: segW, height: h)
                }
            }
        }
    }
}

struct EdgeFadeMask: View {
    var fade: CGFloat = 0.10   // fraction of each dimension

    var body: some View {
        GeometryReader { geo in
            let fw = geo.size.width * fade
            let fh = geo.size.height * fade

            // horizontal fade ∩ vertical fade
            LinearGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .white, location: fade),
                .init(color: .white, location: 1 - fade),
                .init(color: .clear, location: 1)
            ], startPoint: .leading, endPoint: .trailing)
            .mask(
                LinearGradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white, location: fade),
                    .init(color: .white, location: 1 - fade),
                    .init(color: .clear, location: 1)
                ], startPoint: .top, endPoint: .bottom)
            )
        }
    }
}

#Preview {
    MainPageView()
        .environment(AppState())
}
