//
//  AdConsentManager.swift
//  Penny Impact
//
//  Refreshes UMP consent on every launch. Ads are requested only when
//  Google's current consent state permits them.
//

import Foundation
import GoogleMobileAds
import GoogleUserMessagingPlatform

@MainActor
final class AdConsentManager: ObservableObject {
    static let shared = AdConsentManager()

    @Published private(set) var canRequestAds = false
    @Published private(set) var privacyOptionsRequired = false
    @Published private(set) var consentError: String?

    private var hasStartedAdsSDK = false

    private init() {}

    func updateConsent() async {
        let parameters = RequestParameters()

        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
            consentError = nil
        } catch {
            consentError = error.localizedDescription
            NSLog("Penny Impact: UMP consent update failed: %@", error.localizedDescription)
        }

        // UMP retains the previous session's consent state when a refresh fails.
        canRequestAds = ConsentInformation.shared.canRequestAds
        privacyOptionsRequired =
            ConsentInformation.shared.privacyOptionsRequirementStatus == .required

        guard canRequestAds, !hasStartedAdsSDK else { return }
        hasStartedAdsSDK = true
        MobileAds.shared.start()
    }

    func presentPrivacyOptions() async {
        guard privacyOptionsRequired else { return }

        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            consentError = nil
        } catch {
            consentError = error.localizedDescription
            NSLog("Penny Impact: UMP privacy options failed: %@", error.localizedDescription)
        }

        canRequestAds = ConsentInformation.shared.canRequestAds
        privacyOptionsRequired =
            ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }
}
