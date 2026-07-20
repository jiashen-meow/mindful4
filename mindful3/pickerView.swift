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
                Button("start battle!") {
                    // Add your battle logic here
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
}

#Preview {
    pickerView()
}
