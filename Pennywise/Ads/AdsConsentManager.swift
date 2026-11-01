//
//  AdsConsentManager.swift
//  Pennywise
//
//  Runs the permission flow in the order Google and Apple expect:
//
//    1. UMP consent (GDPR / US state privacy messages, if they apply)
//    2. App Tracking Transparency prompt (only if still undecided)
//    3. Google Mobile Ads SDK start — only when UMP says ads may be requested
//
//  Nothing ad-related is requested before step 3 succeeds.
//

import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds
import UserMessagingPlatform
import os

@MainActor
final class AdsConsentManager: ObservableObject {

    static let shared = AdsConsentManager()

    /// `true` once UMP reports that ads may be requested.
    @Published private(set) var canRequestAds = false

    /// `true` once the Google Mobile Ads SDK has been started.
    @Published private(set) var isSDKStarted = false

    /// `true` when the user must be offered a way to change their
    /// privacy choices (required in the EEA, UK and Switzerland).
    @Published private(set) var isPrivacyOptionsRequired = false

    private var isGathering = false
    private let log = Logger(subsystem: "Me.Pennywise", category: "Ads")

    private init() {}

    // MARK: - Launch flow

    /// Call whenever the app becomes active. Safe to call repeatedly.
    func gatherConsentIfNeeded() async {
        guard !isGathering else { return }
        isGathering = true
        defer { isGathering = false }

        // Consent from a previous launch can be used immediately,
        // so returning users don't wait on the network.
        refreshState()
        startSDKIfAllowed()

        do {
            try await requestConsentInfoUpdate()
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            // Offline or form error: fall back to whatever consent is cached.
            log.error("UMP consent flow failed: \(error.localizedDescription, privacy: .public)")
        }

        await requestTrackingAuthorizationIfNeeded()

        refreshState()
        startSDKIfAllowed()

        if AdsConfiguration.isUsingTestIDs {
            #if DEBUG
            log.info("Using Google test ad IDs (expected in Debug).")
            #else
            log.fault("Release build is using Google TEST ad IDs. Set GAD_APPLICATION_IDENTIFIER and PENNY_NATIVE_AD_UNIT_ID for Release.")
            #endif
        }
    }

    /// Re-opens the UMP privacy options form (shown from About → Privacy).
    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        } catch {
            log.error("Privacy options form failed: \(error.localizedDescription, privacy: .public)")
        }
        refreshState()
        if !canRequestAds {
            NativeAdCache.shared.clearAll()
        }
    }

    // MARK: - Steps

    private func requestConsentInfoUpdate() async throws {
        let parameters = RequestParameters()
        // Penny Impact is a general-audience app used by adults and teachers;
        // it is not directed at children, so no under-age-of-consent tag is set.

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Shows Apple's tracking prompt once. If UMP already showed it
    /// (via an IDFA explainer message in AdMob), status is no longer
    /// `.notDetermined` and nothing happens here.
    private func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        let status = await ATTrackingManager.requestTrackingAuthorization()
        log.info("ATT status: \(status.rawValue, privacy: .public)")
    }

    private func startSDKIfAllowed() {
        guard canRequestAds, !isSDKStarted else { return }

        // Keep every ad family-friendly: this app is shown in classrooms.
        MobileAds.shared.requestConfiguration.maxAdContentRating = .general

        MobileAds.shared.start(completionHandler: nil)
        isSDKStarted = true
    }

    private func refreshState() {
        canRequestAds = ConsentInformation.shared.canRequestAds
        isPrivacyOptionsRequired =
            ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }
}
