//
//  PhoneTabShell.swift
//  Pennywise
//
//  Adaptive iPhone tab shell for Pennywise
//

import SwiftUI

@MainActor
struct PhoneTabShell: View {
    @State private var selectedTab: PennyTab = .impact

    var body: some View {
        TabView(selection: $selectedTab) {

            // IMPACT
            NavigationStack {
                EverydayImpactView()
                    .navigationTitle(PennyTab.impact.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Impact", systemImage: PennyTab.impact.systemImage)
            }
            .tag(PennyTab.impact)

            // JOURNAL & COACH
            NavigationStack {
                RoundingJournalView()
                    .navigationTitle(PennyTab.journal.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Journal", systemImage: PennyTab.journal.systemImage)
            }
            .tag(PennyTab.journal)

            // BUSINESS
            NavigationStack {
                BusinessToolsView()
                    .navigationTitle(PennyTab.business.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Business", systemImage: PennyTab.business.systemImage)
            }
            .tag(PennyTab.business)

            // LEARN
            NavigationStack {
                LearnTeachView()
                    .navigationTitle(PennyTab.learn.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Learn", systemImage: PennyTab.learn.systemImage)
            }
            .tag(PennyTab.learn)

            // ECONOMICS
            NavigationStack {
                EconomicsView()
                    .navigationTitle(PennyTab.economics.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("Economics", systemImage: PennyTab.economics.systemImage)
            }
            .tag(PennyTab.economics)

            // ABOUT (+ Support in toolbar)
            NavigationStack {
                AboutView()
                    .navigationTitle(PennyTab.about.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        NavigationLink {
                            SupportView()
                        } label: {
                            Label("Support", systemImage: "hands.sparkles")
                        }
                    }
            }
            .tabItem {
                Label("About", systemImage: PennyTab.about.systemImage)
            }
            .tag(PennyTab.about)
        }
        .tint(PennyTheme.accentCopper)
    }
}
