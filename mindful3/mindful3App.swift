//
//  mindful3App.swift
//  mindful3
//
//  Created by Jia Shen on 9/20/25.
//

import SwiftUI
import FamilyControls

@main
struct MindfulApp: App {
    let center = AuthorizationCenter.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    Task {
                        do {
                            try await center.requestAuthorization(for: .individual)
                            print("Authorization granted")
                        } catch {
                            print("Failed to enroll user with error: \(error)")
                        }
                    }
                }
        }
    }
}
