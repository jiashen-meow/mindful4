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
    @State private var foulSelection = FamilyActivitySelection()
    @State private var showingFriendPicker = false
    @State private var showingFoulPicker = false
    @State private var context: DeviceActivityReport.Context = .totalActivity
    @State private var friendContext: DeviceActivityReport.Context = .friendAppActivity
    @State private var foulContext: DeviceActivityReport.Context = .foulAppActivity
    
    // Add loading states for better UX
    @State private var isFriendReportLoading = false
    @State private var isFoulReportLoading = false

    // Incremented each time "start battle!" is tapped so SwiftUI rebuilds
    // the DeviceActivityReport views with the latest filter.
    @State private var battleID: Int = 0

    // Counters written by the monitor extension, read here.
    @State private var thresholdCount: Int = SharedStore.thresholdCount
    @State private var foulThresholdCount: Int = SharedStore.foulThresholdCount
    
    @State private var segmentInterval: DeviceActivityFilter.SegmentInterval = .daily(
        during: Calendar.current.dateInterval(of: .day, for: .now)!
    )
    
    // Optimize filter creation - only include selected items to reduce data processing
    private var friendFilter: DeviceActivityFilter {
        DeviceActivityFilter(
            segment: segmentInterval,
            applications: Set(friendSelection.applicationTokens), // Use Set for faster lookups
            categories: Set(friendSelection.categoryTokens),
            webDomains: Set(friendSelection.webDomainTokens)
        )
    }
    
    private var foulFilter: DeviceActivityFilter {
        DeviceActivityFilter(
            segment: segmentInterval,
            applications: Set(foulSelection.applicationTokens), // Use Set for faster lookups
            categories: Set(foulSelection.categoryTokens),
            webDomains: Set(foulSelection.webDomainTokens)
        )
    }
    
    var body: some View {
        VStack {
            Divider()
            if friendSelection.categoryTokens.isEmpty && friendSelection.applicationTokens.isEmpty {
                Button("pick your friend") {
                    showingFriendPicker = true
                }
                .padding(100)
            } else {
                VStack(spacing: 4) {
                    Text("⚔️ Friend hits: \(thresholdCount)")
                        .font(.headline)
                        .padding(.top, 8)

                    if isFriendReportLoading {
                        ProgressView("Loading friend app data...")
                            .frame(height: 100)
                    }

                    ScrollView {
                        DeviceActivityReport(friendContext, filter: friendFilter)
                            .id(battleID)
                            .frame(minHeight: 300)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .onAppear {
                                isFriendReportLoading = true
                                print("DeviceActivityReport appeared")
                                print("Context: \(friendContext)")
                                print("Filter segment: \(friendFilter.segmentInterval)")
                                print("Selected apps: \(friendSelection.applicationTokens)")
                                print("Selected categories: \(friendSelection.categoryTokens)")

                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    isFriendReportLoading = false
                                }
                            }
                    }
                }
            }

            if foulSelection.categoryTokens.isEmpty && foulSelection.applicationTokens.isEmpty {
                Button("pick your foul") {
                    showingFoulPicker = true
                }
                .padding(100)
            } else {
                VStack(spacing: 4) {
                    Text("💀 Foul hits: \(foulThresholdCount)")
                        .font(.headline)
                        .padding(.top, 8)

                    if isFoulReportLoading {
                        ProgressView("Loading foul app data...")
                            .frame(height: 100)
                    }

                    ScrollView {
                        DeviceActivityReport(foulContext, filter: foulFilter)
                            .id(battleID)
                            .frame(minHeight: 300)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .onAppear {
                                isFoulReportLoading = true
                                print("DeviceActivityReport appeared")
                                print("Context: \(foulContext)")
                                print("Filter segment: \(foulFilter.segmentInterval)")
                                print("Selected apps: \(foulSelection.applicationTokens)")
                                print("Selected categories: \(foulSelection.categoryTokens)")

                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    isFoulReportLoading = false
                                }
                            }
                    }
                }
            }
            HStack {
                Button("reselect") {
                    isFriendReportLoading = false
                    isFoulReportLoading = false
                    friendSelection = FamilyActivitySelection()
                    foulSelection = FamilyActivitySelection()
                    SharedStore.removeFriendSelection()
                    SharedStore.removeFoulSelection()
                }
                Button("reset count") {
                    SharedStore.resetThresholdCount()
                    SharedStore.resetFoulThresholdCount()
                    thresholdCount = 0
                    foulThresholdCount = 0
                }
                Button("start battle!") {
                    startMonitoring()
                }
                .padding()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Refresh both counters whenever the app returns to the foreground.
            thresholdCount = SharedStore.thresholdCount
            foulThresholdCount = SharedStore.foulThresholdCount
        }
        .onAppear {
            // Restore saved selections so the UI survives app restarts.
            if let saved = SharedStore.loadFriendSelection() {
                friendSelection = saved
            }
            if let saved = SharedStore.loadFoulSelection() {
                foulSelection = saved
            }
            thresholdCount = SharedStore.thresholdCount
            foulThresholdCount = SharedStore.foulThresholdCount
        }
        .sheet(isPresented: $showingFriendPicker) {
            NavigationView {
                FamilyActivityPicker(selection: $friendSelection)
                    .navigationTitle("Select Apps & Categories")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingFriendPicker = false
                                // Persist immediately so it survives app restarts.
                                SharedStore.saveFriendSelection(friendSelection)
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingFoulPicker) {
            NavigationView {
                FamilyActivityPicker(selection: $foulSelection)
                    .navigationTitle("Select Apps & Categories")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingFoulPicker = false
                                // Persist immediately so it survives app restarts.
                                SharedStore.saveFoulSelection(foulSelection)
                            }
                        }
                    }
            }
        }
    }

    private func startMonitoring() {
        let center = DeviceActivityCenter()
        let friendActivity = DeviceActivityName("mindful.daily")
        let foulActivity   = DeviceActivityName("foul.daily")

        // Stop any existing sessions first so we can re-register with
        // the latest selections.
        center.stopMonitoring([friendActivity, foulActivity])

        // Persist both selections.
        SharedStore.saveFriendSelection(friendSelection)
        SharedStore.saveFoulSelection(foulSelection)

        let stepMinutes  = 15
        let maxMilestones = 8   // 8 × 15 min = 2 hours

        let dailySchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd:   DateComponents(hour: 23, minute: 59),
            repeats: true   // OS resets cumulative usage at midnight automatically
        )

        // --- Friend events: "milestone_1" … "milestone_8" ---
        var friendEvents: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for i in 1...maxMilestones {
            friendEvents[DeviceActivityEvent.Name("milestone_\(i)")] = DeviceActivityEvent(
                applications: friendSelection.applicationTokens,
                categories:   friendSelection.categoryTokens,
                webDomains:   friendSelection.webDomainTokens,
                threshold:    DateComponents(minute: i * stepMinutes)
            )
        }

        // --- Foul events: "foul_milestone_1" … "foul_milestone_8" ---
        var foulEvents: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for i in 1...maxMilestones {
            foulEvents[DeviceActivityEvent.Name("foul_milestone_\(i)")] = DeviceActivityEvent(
                applications: foulSelection.applicationTokens,
                categories:   foulSelection.categoryTokens,
                webDomains:   foulSelection.webDomainTokens,
                threshold:    DateComponents(minute: i * stepMinutes)
            )
        }

        do {
            if !friendSelection.applicationTokens.isEmpty || !friendSelection.categoryTokens.isEmpty {
                try center.startMonitoring(friendActivity, during: dailySchedule, events: friendEvents)
                print("Friend monitoring started — \(maxMilestones) milestones")
            }
            if !foulSelection.applicationTokens.isEmpty || !foulSelection.categoryTokens.isEmpty {
                try center.startMonitoring(foulActivity, during: dailySchedule, events: foulEvents)
                print("Foul monitoring started — \(maxMilestones) milestones")
            }
            battleID += 1
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
}

#Preview {
    pickerView()
}
