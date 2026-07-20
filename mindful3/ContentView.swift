//
//  ContentView.swift
//  mindful3
//
//  Created by Jia Shen on 9/20/25.
//

import SwiftUI
import DeviceActivity
import FamilyControls
internal import ManagedSettings

extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
    static let friendAppActivity = Self("Friend App Activity")
    static let foulAppActivity = Self("Foul App Activity")
}

struct ContentView: View {
    @State private var selection = FamilyActivitySelection()
    @State private var context: DeviceActivityReport.Context = .totalActivity
    @State private var showingPicker = false
    @State private var authorizationStatus: AuthorizationStatus = .notDetermined
    @State private var segmentInterval: DeviceActivityFilter.SegmentInterval = .daily(
        during: Calendar.current.dateInterval(of: .day, for: .now)!
    )
    
    private var filter: DeviceActivityFilter {
        DeviceActivityFilter(
            segment: segmentInterval,
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens
        )
    }

    public var body: some View {
        VStack {
            // Show authorization status
            if authorizationStatus == .denied {
                Text("Family Controls access denied. Please enable in Settings.")
                    .foregroundColor(.red)
                    .font(.caption)
            } else if authorizationStatus == .notDetermined {
                Text("Requesting Family Controls permission...")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
            
            if authorizationStatus == .approved {
                pickerView()
            }
        }
        .onAppear {
            // Check current authorization status
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus

            Task {
                if authorizationStatus == .notDetermined {
                    do {
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                        print("Authorization granted")
                        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
                    } catch {
                        print("Failed to enroll user with error: \(error)")
                        authorizationStatus = .denied
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
