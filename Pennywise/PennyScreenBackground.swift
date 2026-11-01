//
//  PennyScreenBackground.swift
//  Pennywise
//
//  Created by Bryan on 12/2/25.
//


// SharedComponents.swift

import SwiftUI

struct PennyScreenBackground<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @State private var animateBackdrop = false

    let title: String
    let subtitle: String?
    let content: () -> Content

    init(title: String,
         subtitle: String? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        ZStack {
            PennyBackdrop(animate: animateBackdrop)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    content()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .frame(maxWidth: 700) // nicer on iPad
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animateBackdrop.toggle()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(PennyTheme.displayFont(size: 34))
                .foregroundColor(PennyTheme.primaryText(scheme))

            if let subtitle {
                Text(subtitle)
                    .font(PennyTheme.bodyFont(size: 15))
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 4)
    }
}

struct PennyBackdrop: View {
    @Environment(\.colorScheme) private var scheme

    let animate: Bool

    var body: some View {
        ZStack {
            PennyTheme.backgroundGradient(scheme)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            PennyTheme.accentCopper.opacity(scheme == .dark ? 0.25 : 0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 240
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: animate ? -140 : -110, y: animate ? -220 : -180)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            PennyTheme.accentMint.opacity(scheme == .dark ? 0.22 : 0.18),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 260
                    )
                )
                .frame(width: 420, height: 420)
                .offset(x: animate ? 160 : 120, y: animate ? 260 : 220)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(Color.white.opacity(scheme == .dark ? 0.04 : 0.30))
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(12))
                .offset(x: animate ? 140 : 100, y: animate ? -180 : -150)
                .blendMode(.softLight)
        }
    }
}

struct PennyCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme

    let title: String?
    let content: () -> Content

    init(title: String? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(PennyTheme.titleFont(size: 18))
                    .foregroundColor(PennyTheme.primaryText(scheme))
            }

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(PennyTheme.cardGradient(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PennyTheme.cardStroke(scheme))
        )
        .shadow(color: PennyTheme.cardShadow(scheme),
                radius: 20, x: 0, y: 12)
    }
}

struct StatPill: View {
    @Environment(\.colorScheme) private var scheme

    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(PennyTheme.accentCopper)
            Text(label)
                .font(PennyTheme.bodyFont(size: 12))
                .lineLimit(1)
            Spacer()
            Text(value)
                .font(PennyTheme.titleFont(size: 12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(PennyTheme.pillGradient(scheme))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(PennyTheme.pillStroke(scheme))
        )
    }
}
