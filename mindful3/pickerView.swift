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

    // Counter written by the monitor extension, read here.
    @State private var thresholdCount: Int = SharedStore.thresholdCount
    
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
            // --- Battle counter ---
            Text("⚔️ Threshold hits: \(thresholdCount)")
                .font(.headline)
                .padding(.top)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Refresh whenever the app comes back to the foreground,
                    // since the extension wrote to shared UserDefaults while we were away.
                    thresholdCount = SharedStore.thresholdCount
                }
            
            Divider()
            if friendSelection.categoryTokens.isEmpty && friendSelection.applicationTokens.isEmpty {
                Button("pick your friend") {
                    showingFriendPicker = true
                }
                .padding(100)
            } else {
                VStack {
                    if isFriendReportLoading {
                        ProgressView("Loading friend app data...")
                            .frame(height: 100)
                    }
                    
                    ScrollView {
                        DeviceActivityReport(friendContext, filter: friendFilter)
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
                                
                                // Simulate completion - in practice, the report will load asynchronously
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
                VStack {
                    if isFoulReportLoading {
                        ProgressView("Loading foul app data...")
                            .frame(height: 100)
                    }
                    
                    ScrollView {
                        DeviceActivityReport(foulContext, filter: foulFilter)
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
                                
                                // Simulate completion - in practice, the report will load asynchronously
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    isFoulReportLoading = false
                                }
                            }
                    }
                }
            }
            HStack {
                Button("reselect") {
                    // Reset loading states when clearing selections
                    isFriendReportLoading = false
                    isFoulReportLoading = false
                    friendSelection = FamilyActivitySelection()
                    foulSelection = FamilyActivitySelection()
                }
                Button("reset count") {
                    SharedStore.resetThresholdCount()
                    thresholdCount = 0
                }
                Button("start battle!") {
                    startMonitoring()
                }
                .padding()
            }

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
                            }
                        }
                    }
            }
        }
    }

    private func startMonitoring() {
        let center = DeviceActivityCenter()
        let activityName = DeviceActivityName("mindful.daily")

        // Build one event per 15-minute milestone for up to 8 hours of coverage
        // (milestone_1 = 15 min, milestone_2 = 30 min, … milestone_32 = 480 min).
        // The threshold accumulates across the interval — no stop/restart needed.
        let stepMinutes = 15
        let maxMilestones = 8  // 8 × 15 min = 2 hours

        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        for i in 1...maxMilestones {
            events[DeviceActivityEvent.Name("milestone_\(i)")] = DeviceActivityEvent(
                applications: friendSelection.applicationTokens,
                categories: friendSelection.categoryTokens,
                webDomains: friendSelection.webDomainTokens,
                threshold: DateComponents(minute: i * stepMinutes)
            )
        }

        do {
            try center.startMonitoring(
                activityName,
                during: DeviceActivitySchedule(
                    intervalStart: DateComponents(hour: 0, minute: 0),
                    intervalEnd: DateComponents(hour: 23, minute: 59),
                    repeats: true   // OS resets cumulative usage at midnight automatically
                ),
                events: events
            )
            print("Monitoring started with \(maxMilestones) milestones (step: \(stepMinutes) min)")
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }
}

#Preview {
    pickerView()
}
