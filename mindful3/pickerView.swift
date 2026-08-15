//
//  pickerView.swift
//  mindful3
//
//  Created by Jia Shen on 9/23/25.
//  Rewritten 7/30/26 — now acts as the root page coordinator.
//  All state lives in AppState (passed via environment).
//

import SwiftUI

struct pickerView: View {

    @Environment(AppState.self) private var state

    var body: some View {
        VStack {
            Group {
                switch state.currentPage {
                case .selection:
                    SelectionPageView()
                case .main:
                    MainPageView()
                case .history:
                    HistoryPageView()
                case .achievements:
                    AchievementPageView()
                }
            }
        }
        // Smooth crossfade between pages.
        .animation(.easeInOut(duration: 0.25), value: state.currentPage)
        .onAppear {
            state.reload()
        }
    }
}

#Preview {
    pickerView()
        .environment(AppState())
}
