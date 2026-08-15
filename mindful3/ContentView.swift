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
    static let totalActivity    = Self("Total Activity")
    static let friendAppActivity = Self("Friend App Activity")
    static let foeAppActivity   = Self("foe App Activity")
}

struct ContentView: View {

    @State private var authorizationStatus: AuthorizationStatus = .notDetermined
    @State private var appState = AppState()

    public var body: some View {
        ZStack {
            switch authorizationStatus {
            case .approved:
                pickerView()
                    .environment(appState)
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
            await requestOrRefreshAuthorization()
        }
        // Re-check every time the app comes back from the background
        // (e.g. user granted access in Settings → Screen Time).
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.didBecomeActiveNotification)
        ) { _ in
            Task { await requestOrRefreshAuthorization() }
        }
    }
    // MARK: - Helpers
    
    @MainActor
    private func requestOrRefreshAuthorization() async {
        // Always re-read the current status first.
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus

        // Only show the system prompt if still undecided.
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

#Preview {
    ContentView()
}
