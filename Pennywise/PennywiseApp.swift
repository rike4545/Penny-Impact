// PennywiseApp.swift

import SwiftUI

@main
struct PennywiseApp: App {

    init() {
        PennyTheme.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}
