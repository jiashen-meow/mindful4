//
//  ContentView.swift
//  mindful3
//
//  Created by Jia Shen on 9/20/25.
//

import SwiftUI
import DeviceActivity
import FamilyControls

extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
    static let friendAppActivity = Self("Friend App Activity")
    static let foulAppActivity = Self("Foul App Activity")
}

struct ContentView: View {
    @State private var authorizationStatus: AuthorizationStatus = .notDetermined

    public var body: some View {
        VStack {
            switch authorizationStatus {
            case .approved:
                pickerView()
            case .denied:
                ContentUnavailableView(
                    "Screen Time Access Required",
                    systemImage: "lock.shield",
                    description: Text("Please enable Family Controls in Settings → Screen Time.")
                )
            case .notDetermined:
                ProgressView("Requesting permission…")
            @unknown default:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 250/255, green: 246/255, blue: 238/255).ignoresSafeArea())
        .task {
            // Re-check status every time the view appears (e.g. returning from Settings).
            authorizationStatus = AuthorizationCenter.shared.authorizationStatus

            guard authorizationStatus == .notDetermined else { return }

            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            } catch {
                print("Family Controls authorization failed: \(error)")
                authorizationStatus = .denied
            }
        }
    }
}

#Preview {
    ContentView()
}
