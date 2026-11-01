//
//  PennyTab.swift
//  Pennywise
//
//  RootTabView.swift
//  Pennywise – adaptive shell for iPhone + iPad
//

import SwiftUI

/// Main sections of the app
enum PennyTab: String, CaseIterable, Identifiable {
    case impact       // Everyday impact simulator
    case journal      // My data + AI coach
    case business     // For businesses / cashiers
    case learn        // Learn & teach
    case economics    // Economics of the penny
    case about        // About & support

    var id: String { rawValue }

    var title: String {
        switch self {
        case .impact:
            return "Everyday Impact"
        case .journal:
            return "Journal & Coach"
        case .business:
            return "For Businesses"
        case .learn:
            return "Learn & Teach"
        case .economics:
            return "Economics"
        case .about:
            return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .impact:
            return "person.2.wave.2"
        case .journal:
            // Your personal data + AI-ish insights
            return "sparkles.rectangle.stack"
        case .business:
            return "bag.badge.plus"
        case .learn:
            return "book.closed"
        case .economics:
            return "chart.bar.doc.horizontal"
        case .about:
            return "info.circle"
        }
    }
}

@MainActor
struct RootTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        // iPhone / compact width → tab bar
        if horizontalSizeClass == .compact {
            PhoneTabShell()
        } else {
            // iPad / regular width → sidebar
            TabletSidebarShell()
        }
    }
}
