//
//  TabletSidebarShell.swift
//  Pennywise
//
//  Adaptive iPad shell with a sidebar of Pennywise sections.
//

import SwiftUI

@MainActor
struct TabletSidebarShell: View {
    @State private var selectedTab: PennyTab = .impact

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            NavigationStack {
                detailView(for: selectedTab)
            }
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List {
            ForEach(PennyTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack {
                        Image(systemName: tab.systemImage)
                        Text(tab.title)
                    }
                    .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.primary)
                }
                .buttonStyle(.plain)
                .listRowBackground(
                    selectedTab == tab
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear
                )
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Pennywise")
    }

    // MARK: - Detail

    @ViewBuilder
    private func detailView(for tab: PennyTab) -> some View {
        switch tab {
        case .impact:
            EverydayImpactView()
                .navigationTitle(tab.title)
                .navigationBarTitleDisplayMode(.inline)

        case .journal:
            RoundingJournalView()
                .navigationTitle(tab.title)
                .navigationBarTitleDisplayMode(.inline)

        case .business:
            BusinessToolsView()
                .navigationTitle(tab.title)
                .navigationBarTitleDisplayMode(.inline)

        case .learn:
            LearnTeachView()
                .navigationTitle(tab.title)
                .navigationBarTitleDisplayMode(.inline)

        case .economics:
            EconomicsView()
                .navigationTitle(tab.title)
                .navigationBarTitleDisplayMode(.inline)

        case .about:
            AboutView()
                .navigationTitle(tab.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    NavigationLink {
                        SupportView()
                    } label: {
                        Label("Support", systemImage: "hands.sparkles")
                    }
                }
        }
    }
}
