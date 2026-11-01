//
//  AdsConfiguration.swift
//  Pennywise
//
//  Single source of truth for ad settings:
//  • Ad unit IDs (read from Info.plist, set per build configuration)
//  • One unique native ad unit per placement, for clean AdMob reporting
//  • Which screens are allowed to carry a sponsored card
//  • Classroom mode (teachers can hide every sponsored card)
//

import Foundation

/// Every screen that is allowed to show one sponsored card.
///
/// Classroom-facing screens (Learn & Teach, the teacher worksheet,
/// Support) are intentionally *not* listed, so no ad can ever be
/// rendered there.
enum AdPlacement: String, CaseIterable, Identifiable, Sendable {
    case everydayImpact
    case journal
    case business
    case economics
    case about

    var id: String { rawValue }

    /// Info.plist key holding this placement's own native ad unit ID.
    /// Values come from build settings, e.g. `PENNY_NATIVE_AD_UNIT_ID_IMPACT`.
    var infoPlistKey: String {
        switch self {
        case .everydayImpact: return "PennyNativeAdUnitID_Impact"
        case .journal:        return "PennyNativeAdUnitID_Journal"
        case .business:       return "PennyNativeAdUnitID_Business"
        case .economics:      return "PennyNativeAdUnitID_Economics"
        case .about:          return "PennyNativeAdUnitID_About"
        }
    }
}

enum AdsConfiguration {

    // MARK: - Info.plist keys

    /// Shared fallback native ad unit, used by any placement whose own
    /// key is empty. Value comes from `PENNY_NATIVE_AD_UNIT_ID`.
    static let defaultNativeAdUnitInfoKey = "PennyNativeAdUnitID"

    /// Standard Google Mobile Ads key holding the AdMob app ID.
    /// Value comes from `GAD_APPLICATION_IDENTIFIER`.
    static let applicationIdentifierInfoKey = "GADApplicationIdentifier"

    // MARK: - Google's public test IDs

    /// Google's sample AdMob app ID. Safe for development only.
    static let testApplicationIdentifier = "ca-app-pub-3940256099942544~1458002511"

    /// Google's sample native ad unit (image or video creatives).
    static let testNativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"

    /// Google's sample native *video* ad unit — handy for checking playback.
    static let testNativeVideoAdUnitID = "ca-app-pub-3940256099942544/2521693316"

    // MARK: - User setting

    /// `@AppStorage` key for Classroom mode. When `true`, no sponsored
    /// cards are requested or shown anywhere in the app.
    static let classroomModeKey = "penny_classroom_mode"

    // MARK: - Resolved values

    static func nativeAdUnitID(for placement: AdPlacement) -> String {
        resolvedNativeAdUnitID(for: placement, info: Bundle.main.infoDictionary)
    }

    /// `true` when this build is still pointing at any Google test ID.
    static var isUsingTestIDs: Bool {
        usesTestIDs(info: Bundle.main.infoDictionary)
    }

    // MARK: - Pure helpers (unit-tested)

    /// Placement key → shared key → Google test unit.
    static func resolvedNativeAdUnitID(for placement: AdPlacement,
                                       info: [String: Any]?) -> String {
        if let id = cleaned(info?[placement.infoPlistKey]) { return id }
        if let id = cleaned(info?[defaultNativeAdUnitInfoKey]) { return id }
        return testNativeAdUnitID
    }

    static func usesTestIDs(info: [String: Any]?) -> Bool {
        let testUnits: Set<String> = [testNativeAdUnitID, testNativeVideoAdUnitID]
        let appID = info?[applicationIdentifierInfoKey] as? String ?? ""
        if appID == testApplicationIdentifier { return true }
        return AdPlacement.allCases.contains {
            testUnits.contains(resolvedNativeAdUnitID(for: $0, info: info))
        }
    }

    /// Whether a sponsored card may be shown on a given screen.
    static func shouldShowAd(at placement: AdPlacement,
                             classroomMode: Bool,
                             canRequestAds: Bool) -> Bool {
        guard canRequestAds, !classroomMode else { return false }
        return AdPlacement.allCases.contains(placement)
    }

    /// Empty strings and unexpanded `$(BUILD_SETTING)` values count as missing.
    private static func cleaned(_ value: Any?) -> String? {
        guard let raw = (value as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty, !raw.hasPrefix("$(") else { return nil }
        return raw
    }
}
