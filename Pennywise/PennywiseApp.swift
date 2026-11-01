// PennywiseApp.swift

import SwiftUI

@main
struct PennywiseApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        PennyTheme.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                // Consent + tracking prompts must run while the app is
                // active (Apple ignores the ATT prompt otherwise).
                .task(id: scenePhase) {
                    guard scenePhase == .active else { return }
                    await AdsConsentManager.shared.gatherConsentIfNeeded()
                }
        }
    }
}
