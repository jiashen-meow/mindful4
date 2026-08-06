//
//  ConfirmationPageView.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Ghost vs cat explainer shown once before the first battle starts.
//  "Let's do this!" triggers startBattle() on AppState.
//

import SwiftUI

struct ConfirmationPageView: View {

    @Environment(AppState.self) private var state

    var body: some View {
        ZStack(alignment: .topLeading) {

            Color(red: 250/255, green: 246/255, blue: 238/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // ── Mascot row ────────────────────────────────────────────
                HStack(alignment: .bottom, spacing: 0) {

                    VStack(spacing: 8) {
                        Image("bag-happy")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                        Text("plastic bag")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }

                    Text("vs")
                        .font(.appHeadline)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                    VStack(spacing: 8) {
                        Image("cat-idle")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                        Text("caaat")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer().frame(height: 32)

                // ── Rule explainer ────────────────────────────────────────
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image("icon-sun")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("foul app minutes feed the foul")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image("cat-idle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("friend app minutes feed caaat")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image("icon-moon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        Text("at midnight, they duel · stronger one wins")
                            .font(.appCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 48)

                // ── CTA ───────────────────────────────────────────────────
                Button {
                    state.startBattle()
                } label: {
                    Image("buttonLetsDoThis")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 64)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // ── "Go back to selection" ────────────────────────────────────
            Button {
                state.currentPage = .selected
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("go back to selection")
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
}

#Preview {
    ConfirmationPageView()
        .environment(AppState())
}
