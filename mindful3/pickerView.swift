//
//  pickerView.swift
//  mindful3
//
//  Created by Jia Shen on 9/23/25.
//

import SwiftUI
import FamilyControls
import DeviceActivity

struct pickerView: View {
    @State private var friendSelection = FamilyActivitySelection()
    @State private var foulSelection   = FamilyActivitySelection()
    @State private var showingFriendPicker  = false
    @State private var showingFoulPicker    = false
    @State private var showingFriendReport  = false
    @State private var showingFoulReport    = false
    @State private var friendReportFilter:  DeviceActivityFilter? = nil
    @State private var foulReportFilter:    DeviceActivityFilter? = nil

    // Counters written by the DeviceActivityMonitor extension, read here.
    @State private var thresholdCount:     Int = SharedStore.thresholdCount
    @State private var foulThresholdCount: Int = SharedStore.foulThresholdCount

    /// Controls which page is shown. Starts on the selection page;
    /// flips to the battle page once the user taps the confirmation button.
    @State private var showBattlePage: Bool = false

    @State private var segmentInterval: DeviceActivityFilter.SegmentInterval = .daily(
        during: Calendar.current.dateInterval(of: .day, for: .now)!
    )

    // MARK: - Computed helpers

    private var hasFriendSelection: Bool {
        !friendSelection.applicationTokens.isEmpty || !friendSelection.categoryTokens.isEmpty
    }

    private var hasFoulSelection: Bool {
        !foulSelection.applicationTokens.isEmpty || !foulSelection.categoryTokens.isEmpty
    }

    private var bothSelected: Bool {
        hasFriendSelection && hasFoulSelection
    }

    private var friendFilter: DeviceActivityFilter {
        DeviceActivityFilter(
            segment: segmentInterval,
            applications: Set(friendSelection.applicationTokens),
            categories:   Set(friendSelection.categoryTokens),
            webDomains:   Set(friendSelection.webDomainTokens)
        )
    }

    private var foulFilter: DeviceActivityFilter {
        DeviceActivityFilter(
            segment: segmentInterval,
            applications: Set(foulSelection.applicationTokens),
            categories:   Set(foulSelection.categoryTokens),
            webDomains:   Set(foulSelection.webDomainTokens)
        )
    }

    private var friendIsWinning: Bool {
        thresholdCount > foulThresholdCount
    }

    // MARK: - Body

    var body: some View {
        if showBattlePage {
            battlePage
        } else {
            selectionPage
        }
    }

    // MARK: - Selection Page

    private var selectionPage: some View {
        VStack(spacing: 0) {
            // Top half: foul app slot
            Button {
                showingFoulPicker = true
            } label: {
                Image(hasFoulSelection ? "foulAppSelected" : "pickFoulApp")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom half: friend app slot
            Button {
                showingFriendPicker = true
            } label: {
                Image(hasFriendSelection ? "friendAppSelected" : "pickFriendApp")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Confirmation button — only tappable when both apps are selected
            HStack {
                Spacer()
                Button {
                    guard bothSelected else { return }
                    startMonitoring()
                    showBattlePage = true
                    // Give the OS ~2s to wake the extension and fire catch-up milestones,
                    // then pull the latest values from the shared container.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        SharedStore.defaults.synchronize()
                        thresholdCount     = SharedStore.thresholdCount
                        foulThresholdCount = SharedStore.foulThresholdCount
                    }
                } label: {
                    Image("buttonSelectionConfirmation")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 64)
                        .opacity(bothSelected ? 1.0 : 0.4)
                }
                .disabled(!bothSelected)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        // ── Pickers ───────────────────────────────────────────────────────
        .sheet(isPresented: $showingFoulPicker) {
            NavigationView {
                FamilyActivityPicker(selection: $foulSelection)
                    .navigationTitle("Select Foul Apps")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingFoulPicker = false
                                SharedStore.saveFoulSelection(foulSelection)
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingFriendPicker) {
            NavigationView {
                FamilyActivityPicker(selection: $friendSelection)
                    .navigationTitle("Select Friend Apps")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingFriendPicker = false
                                SharedStore.saveFriendSelection(friendSelection)
                            }
                        }
                    }
            }
        }
        // ── Lifecycle ─────────────────────────────────────────────────────
        .onAppear {
            SharedStore.defaults.synchronize()
            if let saved = SharedStore.loadFriendSelection() { friendSelection = saved }
            if let saved = SharedStore.loadFoulSelection()   { foulSelection   = saved }
            thresholdCount     = SharedStore.thresholdCount
            foulThresholdCount = SharedStore.foulThresholdCount
            // If both selections were already saved and monitoring is active,
            // jump straight to the battle page.
            if hasFriendSelection && hasFoulSelection && SharedStore.isMonitoring {
                showBattlePage = true
            }
        }
    }

    // MARK: - Battle Page

    private var battlePage: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let rowH = geo.size.height / 8
                let colW = geo.size.width  / 3

                VStack(spacing: 0) {
                    // ── Foul mascot (trailing-aligned) ────────────────────
                    // Row 1 (2 rows tall): spacer (1/3) | foul mascot (2/3)
                    HStack(spacing: 0) {
                        Color.clear
                            .frame(width: colW, height: rowH * 2)
                        foulMascotView
                            .frame(width: colW * 2, height: rowH * 2)
                    }

                    // Row 2: spacer (1/3) | foul HP bar (2/3)
                    HStack(spacing: 0) {
                        Color.clear
                            .frame(width: colW, height: rowH)
                        foulLeadingView
                            .frame(width: colW * 2, height: rowH)
                    }

                    // ── Friend mascot (leading-aligned) ───────────────────
                    // Row 3 (4 rows tall): friend mascot (2/3) | spacer (1/3)
                    HStack(spacing: 0) {
                        friendMascotView
                            .frame(width: colW * 2, height: rowH * 4)
                        Color.clear
                            .frame(width: colW, height: rowH * 4)
                    }

                    // Row 4: friend HP bar (2/3) | spacer (1/3)
                    HStack(spacing: 0) {
                        friendTrailingView
                            .frame(width: colW * 2, height: rowH)
                        Color.clear
                            .frame(width: colW, height: rowH)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // ── Bottom action buttons ─────────────────────────────────────
            HStack(spacing: 32) {
                // Reselect — goes back to the selection page
                Button {
                    friendSelection = FamilyActivitySelection()
                    foulSelection   = FamilyActivitySelection()
                    SharedStore.removeFriendSelection()
                    SharedStore.removeFoulSelection()
                    SharedStore.resetThresholdCount()
                    SharedStore.resetFoulThresholdCount()
                    SharedStore.lastResetDate = ""
                    SharedStore.isMonitoring  = false
                    DeviceActivityCenter().stopMonitoring()
                    thresholdCount     = 0
                    foulThresholdCount = 0
                    showBattlePage     = false
                } label: {
                    Image("buttonReselect")
                        .resizable()
                        .scaledToFit()
                }

                // Calendar (placeholder)
                Button {
                    // TODO: calendar feature
                } label: {
                    Image("buttonCalendar")
                        .resizable()
                        .scaledToFit()
                }

                // Sticker (placeholder)
                Button {
                    // TODO: sticker feature
                } label: {
                    Image("buttonSticker")
                        .resizable()
                        .scaledToFit()
                }
            }
            .frame(height: 64)
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 32)
        }
        // ── Report sheets ─────────────────────────────────────────────────
        .sheet(isPresented: $showingFriendReport) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(uiColor: .systemGray4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                if let filter = friendReportFilter {
                    DeviceActivityReport(.friendAppActivity, filter: filter)
                        .id("friendReport")
                }

                Spacer()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showingFoulReport) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(uiColor: .systemGray4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                if let filter = foulReportFilter {
                    DeviceActivityReport(.foulAppActivity, filter: filter)
                        .id("foulReport")
                }

                Spacer()
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
        // ── Live counter updates ──────────────────────────────────────────
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            SharedStore.defaults.synchronize()
            thresholdCount     = SharedStore.thresholdCount
            foulThresholdCount = SharedStore.foulThresholdCount
        }
        // Catches writes made by the DeviceActivityMonitor extension
        // while the app is already in the foreground.
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: SharedStore.defaults)) { _ in
            let newFriend = SharedStore.thresholdCount
            let newFoul   = SharedStore.foulThresholdCount
            if newFriend != thresholdCount     { thresholdCount     = newFriend }
            if newFoul   != foulThresholdCount { foulThresholdCount = newFoul   }
        }
    }

    // MARK: - Sub-views

    /// Foul HP bar — tapping opens the foul usage report sheet.
    @ViewBuilder
    private var foulLeadingView: some View {
        Image("foulHP\(foulThresholdCount)")
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

    /// Foul mascot — unhappy when friend is winning, normal otherwise.
    private var foulMascotView: some View {
        Image(friendIsWinning ? "foulMascotUnhappy" : "foulMascot")
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

    /// Friend mascot — happy when friend is winning, unhappy otherwise.
    private var friendMascotView: some View {
        Image(friendIsWinning ? "friendMascot" : "friendMascotUnhappy")
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

    /// Friend HP bar — tapping opens the friend usage report sheet.
    @ViewBuilder
    private var friendTrailingView: some View {
        Image("catHP\(thresholdCount)")
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

    // MARK: - Monitoring

    private func startMonitoring() {
        guard !SharedStore.isMonitoring else {
            print("Monitoring already active — skipping startMonitoring()")
            return
        }

        let center         = DeviceActivityCenter()
        let friendActivity = DeviceActivityName("mindful.daily")
        let foulActivity   = DeviceActivityName("foul.daily")

        center.stopMonitoring([friendActivity, foulActivity])

        SharedStore.saveFriendSelection(friendSelection)
        SharedStore.saveFoulSelection(foulSelection)

        let stepMinutes   = 15
        let maxMilestones = 8   // 8 × 15 min = 2 hours

        let dailySchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd:   DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // Friend events: "milestone_1" … "milestone_8"
        var friendEvents: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for i in 1...maxMilestones {
            friendEvents[DeviceActivityEvent.Name("milestone_\(i)")] = DeviceActivityEvent(
                applications:        friendSelection.applicationTokens,
                categories:          friendSelection.categoryTokens,
                webDomains:          friendSelection.webDomainTokens,
                threshold:           DateComponents(minute: i * stepMinutes),
                includesPastActivity: true
            )
        }

        // Foul events: "foul_milestone_1" … "foul_milestone_8"
        var foulEvents: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for i in 1...maxMilestones {
            foulEvents[DeviceActivityEvent.Name("foul_milestone_\(i)")] = DeviceActivityEvent(
                applications:        foulSelection.applicationTokens,
                categories:          foulSelection.categoryTokens,
                webDomains:          foulSelection.webDomainTokens,
                threshold:           DateComponents(minute: i * stepMinutes),
                includesPastActivity: true
            )
        }

        do {
            if hasFriendSelection {
                try center.startMonitoring(friendActivity, during: dailySchedule, events: friendEvents)
                print("Friend monitoring started — \(maxMilestones) milestones")
            }
            if hasFoulSelection {
                try center.startMonitoring(foulActivity, during: dailySchedule, events: foulEvents)
                print("Foul monitoring started — \(maxMilestones) milestones")
            }
            SharedStore.isMonitoring  = true
            SharedStore.lastResetDate = SharedStore.todayString
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
}

#Preview {
    pickerView()
}
