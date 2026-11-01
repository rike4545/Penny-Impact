//
//  BulletPoint.swift
//  Pennywise
//
//  Created by Bryan on 12/3/25.
//


//
//  BulletPoint.swift
//  Pennywise
//
//  Small helper for labeled bullet rows used across the app.
//

import SwiftUI

struct BulletPoint: View {
    @Environment(\.colorScheme) private var scheme

    let text: String
    let iconName: String?

    /// Use `BulletPoint(text: "…")` for a simple dot bullet,
    /// or `BulletPoint(text: "…", icon: "star.fill")` for a custom icon.
    init(text: String, icon: String? = nil) {
        self.text = text
        self.iconName = icon
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            bulletView
                .padding(.top, 4)

            Text(text)
                .font(PennyTheme.bodyFont(size: 14))
                .foregroundColor(PennyTheme.primaryText(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var bulletView: some View {
        if let iconName {
            Image(systemName: iconName)
                .font(.caption)
                .foregroundColor(PennyTheme.accentCopper)
        } else {
            Circle()
                .fill(PennyTheme.accentCopper)
                .frame(width: 6, height: 6)
        }
    }
}
