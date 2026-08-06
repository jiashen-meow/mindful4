//
//  SelectedPageView.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Review page shown after the user completes at least one FamilyActivityPicker
//  selection. Shows app-icon squares and "tap to change" labels.
//  Both slots must be filled before "continue" is enabled.
//

import SwiftUI
import FamilyControls

struct SelectedPageView: View {

    @Environment(AppState.self) private var state

    @State private var showingFriendPicker = false
    @State private var showingFoulPicker   = false

    var body: some View {
        @Bindable var state = state

        ZStack(alignment: .topLeading) {

            VStack(spacing: 0) {

                // ── Top half: foul app selection ──────────────────────────
                Button {
                    showingFoulPicker = true
                } label: {
                    if state.hasFoulSelection {
                        selectedSlotView(
                            selection: state.foulSelection,
                            label: "holding its"
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Image("pickFoulApp")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Bottom half: friend app selection ─────────────────────
                Button {
                    showingFriendPicker = true
                } label: {
                    if state.hasFriendSelection {
                        selectedSlotView(
                            selection: state.friendSelection,
                            label: "sitting with"
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Image("pickFriendApp")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Continue button ───────────────────────────────────────
                HStack {
                    Spacer()
                    Button {
                        guard state.bothSelected else { return }
                        state.currentPage = .confirmation
                    } label: {
                        Image("buttonContinue")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 64)
                            .opacity(state.bothSelected ? 1.0 : 0.4)
                    }
                    .disabled(!state.bothSelected)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }

            // ── "Go back to main page" escape ─────────────────────────────
            if state.hasActiveBattle {
                Button {
                    state.currentPage = .main
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("go back to main page")
                            .font(.appCaption)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .padding(.top, 56)
                .padding(.leading, 8)
            }
        }
        // ── Pickers ───────────────────────────────────────────────────────
        .sheet(isPresented: $showingFoulPicker) {
            NavigationView {
                FamilyActivityPicker(selection: $state.foulSelection)
                    .navigationTitle("Select Foul Apps")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingFoulPicker = false
                                SharedStore.saveFoulSelection(state.foulSelection)
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingFriendPicker) {
            NavigationView {
                FamilyActivityPicker(selection: $state.friendSelection)
                    .navigationTitle("Select Friend Apps")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingFriendPicker = false
                                SharedStore.saveFriendSelection(state.friendSelection)
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Selected slot sub-view

    @ViewBuilder
    private func selectedSlotView(
        selection: FamilyActivitySelection,
        label: String
    ) -> some View {
        let appCount  = selection.applicationTokens.count
        let catCount  = selection.categoryTokens.count
        let total     = appCount + catCount
        let displayed = min(total, 3)
        let overflow  = total - displayed

        ZStack {
            Color(red: 250/255, green: 246/255, blue: 238/255)

            VStack(spacing: 12) {

                // App icon row
                HStack(spacing: 8) {
                    ForEach(0..<displayed, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: "app.fill")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                            )
                    }

                    if overflow > 0 {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Text("+\(overflow)")
                                    .font(.appCaption)
                                    .foregroundStyle(.secondary)
                            )
                    }
                }

                // Label: "holding its 5 apps  ·  tap to change"
                Group {
                    Text(label + " ")
                    + Text("\(total) \(total == 1 ? "app" : "apps")")
                        .fontWeight(.bold)
                    + Text("  ·  tap to change")
                        .foregroundStyle(.secondary)
                }
                .font(.appCaption)
                .foregroundStyle(.primary)
            }
            .padding()
        }
    }
}

#Preview {
    SelectedPageView()
        .environment(AppState())
}
