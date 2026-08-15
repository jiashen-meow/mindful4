//
//  SelectionPageView.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Unified selection + review screen.
//
//  • Before selection: each half shows the mascot and a "tap to select" prompt.
//  • After selection: the mascot stays; the prompt is replaced by the chosen
//    app icons and a "tap to change" link.
//  • "continue" becomes enabled once both sides are filled.
//

import SwiftUI
import FamilyControls
internal import ManagedSettings

struct SelectionPageView: View {

    @Environment(AppState.self) private var state

    @State private var showingFriendPicker = false
    @State private var showingfoePicker   = false

    var body: some View {

        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .bottom) {

                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    
                    Spacer()
                    
                    // ── Top half: foe ────────────────────────────────────
                    foeHalf(w: w)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { showingfoePicker = true }
                    
                    Image("backgroundVS")
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 20)
                    
                    // ── Bottom half: friend ───────────────────────────────
                    friendHalf(w: w)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture { showingFriendPicker = true }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // leave room for the button at the bottom
                .padding(.bottom, h * 0.1)

                // ── Continue button ───────────────────────────────────────
                VStack(spacing: 6) {
                    if state.selectionChanged {
                        Text("you have changed your app selections")
                            .appCaption
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    Button {
                        guard state.bothSelected else { return }
                        if state.selectionChanged {
                            state.restartBattle()
                        } else {
                            state.startBattle()
                        }
                    } label: {
                        Image("buttonContinue")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 64)
                            .opacity(state.bothSelected ? 1.0 : 0.4)
                    }
                    .disabled(!state.bothSelected)
                }
                .animation(.easeInOut(duration: 0.2), value: state.selectionChanged)
                .padding(.bottom, h * 0.047)

                // ── "Go back" during active battle ────────────────────────
                if state.hasActiveBattle {
                    VStack {
                        HStack {
                            Button {
                                state.currentPage = .main
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 11, weight: .semibold))
                                    Text("go back")
                                        .appCaption
                                }
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .tint(.primary)
        }
        // ── Pickers ───────────────────────────────────────────────────────
        .sheet(isPresented: $showingfoePicker) {
            NavigationView {
                FamilyActivityPicker(selection: Bindable(state).foeSelection)
                    .navigationTitle("Select foe Apps")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingfoePicker = false
                                // Only persist immediately when there's no active battle.
                                // During a battle, SharedStore is intentionally kept at the
                                // last-started values so selectionChanged can detect a diff.
                                if state.hasfoeSelection && !state.hasActiveBattle {
                                    SharedStore.savefoeSelection(state.foeSelection)
                                }
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingFriendPicker) {
            NavigationView {
                FamilyActivityPicker(selection: Bindable(state).friendSelection)
                    .navigationTitle("Select Friend Apps")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingFriendPicker = false
                                // Same as above — skip the save during an active battle.
                                if state.hasFriendSelection && !state.hasActiveBattle {
                                    SharedStore.saveFriendSelection(state.friendSelection)
                                }
                            }
                        }
                    }
            }
        }
    }

    // MARK: - foe half (top)
    // Bag mascot left · text / icons right

    @ViewBuilder
    private func foeHalf(w: CGFloat) -> some View {
        let mascotW: CGFloat = w * 0.25
        let hasSelection = state.hasfoeSelection

        HStack(alignment: .center, spacing: 0) {
            
            Spacer()
            // Mascot
            Image("bag-happy")
                .resizable()
                .scaledToFit()
                .frame(width: mascotW)
                .padding(.leading, w * 0.08)

            Spacer()

            // Text / icon block — right-aligned
            VStack(alignment: .leading, spacing: 8) {


                if hasSelection {
                    // Selected state: icons + count + "tap to change"
                    let foeTotal = state.foeSelection.applicationTokens.count
                                  + state.foeSelection.categoryTokens.count
                    appIconRow(
                        appTokens: state.foeSelection.applicationTokens,
                        catTokens: state.foeSelection.categoryTokens,
                        w: w,
                        alignment: .trailing
                    )
                    Button {
                        showingfoePicker = true
                    } label: {
                        Text("tap to change")
                            .appCaption
                            .foregroundStyle(.primary)
                            .underline()
                    }
                } else {
                    // Empty state: prompt
                    Text("tap to select foe app")
                        .appBody
                        .foregroundStyle(.primary)
                        .underline()
                }
                
                Text("foe screen time feeds the foe")
                    .appCaption
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.trailing, w * 0.08)
        }
    }

    // MARK: - Friend half (bottom)
    // Text / icons left · cat mascot right

    @ViewBuilder
    private func friendHalf(w: CGFloat) -> some View {
        let mascotW: CGFloat = w * 0.36
        let hasSelection = state.hasFriendSelection

        HStack(alignment: .center, spacing: 0) {

            // Text / icon block — left-aligned
            VStack(alignment: .trailing, spacing: 8) {
                

                if hasSelection {
                    // Selected state: icons + count + "tap to change"
                    let friendTotal = state.friendSelection.applicationTokens.count
                                    + state.friendSelection.categoryTokens.count
                    appIconRow(
                        appTokens: state.friendSelection.applicationTokens,
                        catTokens: state.friendSelection.categoryTokens,
                        w: w,
                        alignment: .leading
                    )
                    Button {
                        showingFriendPicker = true
                    } label: {
                        Text("tap to change")
                            .appCaption
                            .foregroundStyle(.primary)
                            .underline()
                    }
                } else {
                    // Empty state: prompt
                    Text("tap to select friend app")
                        .appBody
                        .foregroundStyle(.primary)
                        .underline()
                }
                
                Text("friend screen time feeds caaat")
                    .appCaption
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.leading, w * 0.08)

            Spacer()

            // Mascot
            Image("cat-idle")
                .resizable()
                .scaledToFit()
                .frame(width: mascotW)
                .padding(.trailing, w * 0.04)
        }
    }

    // MARK: - App icon row helper

    @ViewBuilder
    private func appIconRow(
        appTokens: Set<ApplicationToken>,
        catTokens: Set<ActivityCategoryToken>,
        w: CGFloat,
        alignment: HorizontalAlignment
    ) -> some View {
        let iconSize: CGFloat = w * 0.13   // ~50 pt on 390 pt wide screen
        let maxIcons = 3
        let appSlice = Array(appTokens.prefix(maxIcons))
        let catSlice = Array(catTokens.prefix(max(0, maxIcons - appSlice.count)))
        let total    = appTokens.count + catTokens.count
        let overflow = max(0, total - maxIcons)

        HStack(spacing: 6) {
            ForEach(appSlice, id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .scaleEffect(iconSize / 30)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.22))
            }
            ForEach(catSlice, id: \.self) { token in
                Label(token)
                    .labelStyle(.iconOnly)
                    .scaleEffect(iconSize / 40)
                    .frame(width: iconSize, height: iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.22))
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .appCaption
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview("Nothing selected") {
    SelectionPageView()
        .environment(AppState())
}
