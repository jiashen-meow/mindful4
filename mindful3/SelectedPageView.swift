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
internal import ManagedSettings

struct SelectedPageView: View {

    @Environment(AppState.self) private var state

    @State private var showingFriendPicker = false
    @State private var showingFoulPicker   = false

    /// Snapshots taken the moment this view appears, used to detect changes.
    @State private var originalFriendSelection: FamilyActivitySelection = FamilyActivitySelection()
    @State private var originalFoulSelection:   FamilyActivitySelection = FamilyActivitySelection()

    /// True when the user has changed either selection relative to the snapshot.
    private var hasChanges: Bool {
        state.friendSelection.applicationTokens != originalFriendSelection.applicationTokens ||
        state.friendSelection.categoryTokens    != originalFriendSelection.categoryTokens    ||
        state.friendSelection.webDomainTokens   != originalFriendSelection.webDomainTokens   ||
        state.foulSelection.applicationTokens   != originalFoulSelection.applicationTokens   ||
        state.foulSelection.categoryTokens      != originalFoulSelection.categoryTokens      ||
        state.foulSelection.webDomainTokens     != originalFoulSelection.webDomainTokens
    }

    /// Continue is enabled only when both slots are filled AND something changed.
    private var continueEnabled: Bool {
        state.bothSelected && hasChanges
    }

    var body: some View {
        @Bindable var state = state

        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .topLeading) {

                // ── Background ────────────────────────────────────────────────
                Color(red: 0xF5 / 255.0, green: 0xF0 / 255.0, blue: 0xE8 / 255.0)
                    .ignoresSafeArea()

                VStack(spacing: 0) {

                    Spacer()

                    // ── Top section: foul (bag) ───────────────────────────────
                    foulSection(geo: geo)
                        .padding(.horizontal, w * 0.08) // ~32 pt on 390 pt wide screen

                    Spacer()

                    // ── Bottom section: friend (cat) ──────────────────────────
                    friendSection(geo: geo)
                        .padding(.horizontal, w * 0.08)

                    Spacer()

                    // ── Continue button — centered ────────────────────────────
                    Button {
                        guard continueEnabled else { return }
                        state.currentPage = .confirmation
                    } label: {
                        Image("buttonContinue")
                            .resizable()
                            .scaledToFit()
                            .frame(height: h * 0.075) // ~64 pt on 852 pt tall screen
                            .opacity(continueEnabled ? 1.0 : 0.4)
                    }
                    .disabled(!continueEnabled)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, h * 0.047) // ~40 pt on 852 pt tall screen
                }

                // ── "Go back to main page" escape ─────────────────────────────
                // Always visible during an active battle. If the user changed
                // selections but taps this, we roll back to the originals.
                if state.hasActiveBattle {
                    Button {
                        if hasChanges {
                            state.friendSelection = originalFriendSelection
                            state.foulSelection   = originalFoulSelection
                        }
                        state.currentPage = .main
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                            Text("go back")
                                .font(.appCaption)
                        }
                    }
//                    .padding(.top, h * 0.07)   // ~60 pt on 852 pt tall screen
                    .padding(.leading, w * 0.05) // ~20 pt on 390 pt wide screen
                }
            }
            .tint(.primary)
        }
        .onAppear {
            // Snapshot the selections as they are when this screen opens.
            originalFriendSelection = state.friendSelection
            originalFoulSelection   = state.foulSelection
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
                                // Do NOT save to SharedStore here.
                                // startMonitoring() commits on "let's do this".
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
                                // Do NOT save to SharedStore here.
                                // startMonitoring() commits on "let's do this".
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Foul section (bag mascot on left, icons + label on right)

    private func foulSection(geo: GeometryProxy) -> some View {
        let w         = geo.size.width
        let mascotSize: CGFloat = w * 0.256  // ~100 pt on 390 pt wide screen
        let iconSize: CGFloat   = w * 0.164  // ~64 pt on 390 pt wide screen
        let hSpacing: CGFloat   = w * 0.041  // ~16 pt
        let iSpacing: CGFloat   = w * 0.020  // ~8 pt

        let selection = state.foulSelection
        let appCount  = selection.applicationTokens.count
        let catCount  = selection.categoryTokens.count
        let total     = appCount + catCount
        let overflow  = max(0, total - 3)

        return HStack(alignment: .center, spacing: hSpacing) {

            // Bag mascot
            Image("bag-happy")
                .resizable()
                .scaledToFit()
                .frame(width: mascotSize)

            // Icons + labels
            VStack(alignment: .leading, spacing: iSpacing) {
                HStack(spacing: iSpacing) {
                    ForEach(Array(selection.applicationTokens.prefix(3)), id: \.self) { token in
                        appIconView(token: token, iconSize: iconSize)
                    }
                    ForEach(Array(selection.categoryTokens.prefix(max(0, 3 - appCount))), id: \.self) { token in
                        appIconView(token: token, iconSize: iconSize)
                    }
                    if total == 0 {
                        // Placeholder squares when nothing selected yet
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: iconSize * 0.22)
                                .fill(Color.secondary.opacity(0.15))
                                .frame(width: iconSize, height: iconSize)
                        }
                    }
                    if overflow > 0 {
                        Text("+\(overflow)")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }
                }

                // "holding its X apps" label
                VStack(alignment: .leading, spacing: 2) {
                    Text("holding its \(total) \(total == 1 ? "app" : "apps")")
                        .font(.appCaption)
                        .foregroundStyle(.primary)

                    Button {
                        showingFoulPicker = true
                    } label: {
                        Text("tap to change")
                            .font(.appCaption)
                            .foregroundStyle(.primary)
                            .underline()
                    }
                }
            }

            Spacer()
        }
    }

    // MARK: - Friend section (icons + label on left, cat mascot on right)

    private func friendSection(geo: GeometryProxy) -> some View {
        let w          = geo.size.width
        let mascotSize: CGFloat = w * 0.308  // ~120 pt on 390 pt wide screen
        let iconSize: CGFloat   = w * 0.164  // ~64 pt on 390 pt wide screen
        let hSpacing: CGFloat   = w * 0.041  // ~16 pt
        let iSpacing: CGFloat   = w * 0.020  // ~8 pt

        let selection = state.friendSelection
        let appCount  = selection.applicationTokens.count
        let catCount  = selection.categoryTokens.count
        let total     = appCount + catCount
        let overflow  = max(0, total - 2)

        return HStack(alignment: .center, spacing: hSpacing) {

            Spacer()

            // Icons + labels
            VStack(alignment: .trailing, spacing: iSpacing) {
                HStack(spacing: iSpacing) {
                    ForEach(Array(selection.applicationTokens.prefix(2)), id: \.self) { token in
                        appIconView(token: token, iconSize: iconSize)
                    }
                    ForEach(Array(selection.categoryTokens.prefix(max(0, 2 - appCount))), id: \.self) { token in
                        appIconView(token: token, iconSize: iconSize)
                    }
                    if total == 0 {
                        // Placeholder squares when nothing selected yet
                        ForEach(0..<2, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: iconSize * 0.22)
                                .fill(Color.secondary.opacity(0.15))
                                .frame(width: iconSize, height: iconSize)
                        }
                    }
                    if overflow > 0 {
                        Text("+\(overflow)")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }
                }

                // "sitting with X friends" label
                VStack(alignment: .trailing, spacing: 2) {
                    Text("sitting with \(total) \(total == 1 ? "friend" : "friends")")
                        .font(.appCaption)
                        .foregroundStyle(.primary)

                    Button {
                        showingFriendPicker = true
                    } label: {
                        Text("tap to change")
                            .font(.appCaption)
                            .foregroundStyle(.primary)
                            .underline()
                    }
                }
            }

            // Cat mascot
            Image("cat-idle")
                .resizable()
                .scaledToFit()
                .frame(width: mascotSize)
        }
    }
    // MARK: - App icon helper
    // FamilyControls token Labels render at a fixed ~30 pt internal size regardless
    // of .font(). We measure that natural size and scale it up to fill iconSize.
    @ViewBuilder
    private func appIconView(token: ApplicationToken, iconSize: CGFloat) -> some View {
        Label(token)
            .labelStyle(.iconOnly)
            .scaleEffect(iconSize / 30)
            .frame(width: iconSize, height: iconSize)
            .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.22))
    }

    @ViewBuilder
    private func appIconView(token: ActivityCategoryToken, iconSize: CGFloat) -> some View {
        Label(token)
            .labelStyle(.iconOnly)
            .scaleEffect(iconSize / 30)
            .frame(width: iconSize, height: iconSize)
            .clipShape(RoundedRectangle(cornerRadius: iconSize * 0.22))
    }
}

#Preview {
    SelectedPageView()
        .environment(AppState())
}
