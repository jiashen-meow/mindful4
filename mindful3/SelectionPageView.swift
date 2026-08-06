//
//  SelectionPageView.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Blank "tap to pick" screen shown when neither selection has been made yet,
//  or when the user taps the "app selection" tab from the main battle page.
//

import SwiftUI
import FamilyControls

struct SelectionPageView: View {

    @Environment(AppState.self) private var state

    @State private var showingFriendPicker = false
    @State private var showingFoulPicker   = false

    var body: some View {
        @Bindable var state = state

        ZStack(alignment: .topLeading) {

            VStack(spacing: 0) {

                // ── Top half: foul app slot ───────────────────────────────
                Button {
                    showingFoulPicker = true
                } label: {
                    Image("pickFoulApp")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // ── Bottom half: friend app slot ──────────────────────────
                Button {
                    showingFriendPicker = true
                } label: {
                    Image("pickFriendApp")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // ── "Go back to main page" escape (only during an active battle) ─
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
                                if state.hasFoulSelection {
                                    state.currentPage = .selected
                                }
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
                                if state.hasFriendSelection {
                                    state.currentPage = .selected
                                }
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    SelectionPageView()
        .environment(AppState())
}
