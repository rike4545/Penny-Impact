//
//  PennyTheme 2.swift
//  Pennywise
//
//  Created by Bryan on 12/2/25.
//


//
//  PennyTheme.swift
//  Pennywise
//
//  Copper + mint appearance theme for iPhone and iPad
//

import SwiftUI

struct PennyTheme {

    // MARK: - Brand Colors

    /// Warm copper accent, inspired by the penny.
    static let accentCopper = Color(red: 0.78, green: 0.42, blue: 0.18)

    /// Deep green accent, used for “good” or saving effects.
    static let accentMint = Color(red: 0.18, green: 0.50, blue: 0.36)

    /// Rich ink and cream for high-contrast typography.
    static let accentInk = Color(red: 0.12, green: 0.10, blue: 0.09)
    static let accentCream = Color(red: 0.98, green: 0.97, blue: 0.94)

    // MARK: - Typography

    static func displayFont(size: CGFloat) -> Font {
        .custom("AvenirNext-Heavy", size: size)
    }

    static func titleFont(size: CGFloat) -> Font {
        .custom("AvenirNext-DemiBold", size: size)
    }

    static func bodyFont(size: CGFloat) -> Font {
        .custom("AvenirNext-Regular", size: size)
    }

    static func monoFont(size: CGFloat) -> Font {
        .custom("Menlo", size: size)
    }

    // MARK: - Surfaces

    /// Background gradient that feels like paper/currency in light mode
    /// and a deep, velvety panel in dark mode.
    static func backgroundGradient(_ scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.07),
                    Color(red: 0.10, green: 0.10, blue: 0.13),
                    Color(red: 0.07, green: 0.08, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.98, blue: 0.96),
                    Color(red: 0.96, green: 0.94, blue: 0.91),
                    Color(red: 0.98, green: 0.97, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func cardGradient(_ scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.10),
                    Color.white.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 0.98, green: 0.97, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func cardStroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark
        ? Color.white.opacity(0.18)
        : Color.black.opacity(0.08)
    }

    static func cardShadow(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.black.opacity(0.50) : Color.black.opacity(0.10)
    }

    static func pillGradient(_ scheme: ColorScheme) -> LinearGradient {
        if scheme == .dark {
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    Color.white,
                    Color(red: 0.96, green: 0.95, blue: 0.93)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    static func pillStroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark
        ? Color.white.opacity(0.22)
        : Color.black.opacity(0.08)
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : accentInk
    }

    static func secondaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white.opacity(0.75) : Color.black.opacity(0.60)
    }

    // MARK: - Global UIKit Appearance

    /// Call once at app launch (from PennywiseApp.init()) to tune
    /// navigation bars and tab bars to match the copper theme.
    static func configureAppearance() {
        #if os(iOS)
        let copper = UIColor(red: 0.78, green: 0.42, blue: 0.18, alpha: 1.0)

        // Navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        navAppearance.shadowColor = UIColor.clear

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = copper

        // Tab bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        tabAppearance.stackedLayoutAppearance.selected.iconColor = copper
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: copper
        ]

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = copper
        #endif
    }
}
