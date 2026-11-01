//
//  NativeAdSlot.swift
//  Pennywise
//
//  One native ad per placement, loaded on demand and kept across tab
//  switches so the same screen doesn't burn a new request every visit.
//
//  • Image *and* video creatives compete (media aspect ratio left at "any")
//  • Video starts muted; playback events are tracked via VideoController
//  • Ads are refreshed after ~55 minutes (Google's guidance is < 1 hour)
//  • Failed requests back off for a minute instead of hammering the network
//

import SwiftUI
import Combine
import GoogleMobileAds
import os

@MainActor
final class NativeAdSlot: NSObject, ObservableObject {

    let placement: AdPlacement

    @Published private(set) var nativeAd: NativeAd?

    /// Video playback state, useful for debugging and future analytics.
    @Published private(set) var videoState: VideoState = .none

    enum VideoState: String {
        case none, playing, paused, ended
    }

    private var adLoader: AdLoader?
    private var loadedAt: Date?
    private var lastFailureAt: Date?

    private let maxAdAge: TimeInterval = 55 * 60
    private let retryDelay: TimeInterval = 60
    private let log = Logger(subsystem: "Me.Pennywise", category: "Ads")

    init(placement: AdPlacement) {
        self.placement = placement
        super.init()
    }

    // MARK: - Loading

    func loadIfNeeded(now: Date = .now) {
        let consent = AdsConsentManager.shared
        guard consent.canRequestAds, consent.isSDKStarted else { return }

        if nativeAd != nil, let loadedAt, now.timeIntervalSince(loadedAt) < maxAdAge { return }
        if adLoader?.isLoading == true { return }
        if let lastFailureAt, now.timeIntervalSince(lastFailureAt) < retryDelay { return }

        // Leave media aspect ratio at its default ("any") so image AND
        // video creatives of every shape compete for this slot.
        let mediaOptions = NativeAdMediaAdLoaderOptions()
        mediaOptions.mediaAspectRatio = .any

        // AdChoices sits top-right; the call-to-action sits bottom of the
        // card, so the two never overlap (avoids accidental clicks).
        let viewOptions = NativeAdViewAdOptions()
        viewOptions.preferredAdChoicesPosition = .topRightCorner

        let videoOptions = VideoOptions()
        videoOptions.shouldStartMuted = true

        let loader = AdLoader(
            adUnitID: AdsConfiguration.nativeAdUnitID(for: placement),
            rootViewController: nil,
            adTypes: [.native],
            options: [mediaOptions, viewOptions, videoOptions]
        )
        loader.delegate = self
        adLoader = loader
        loader.load(Request())
    }

    /// Releases the ad (classroom mode switched on, or consent withdrawn).
    func clear() {
        nativeAd?.mediaContent.videoController.delegate = nil
        nativeAd = nil
        loadedAt = nil
        adLoader = nil
        videoState = .none
    }
}

// MARK: - NativeAdLoaderDelegate

extension NativeAdSlot: NativeAdLoaderDelegate {

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        nativeAd.delegate = self

        if nativeAd.mediaContent.hasVideoContent {
            nativeAd.mediaContent.videoController.delegate = self
        }

        self.nativeAd = nativeAd
        loadedAt = .now
        lastFailureAt = nil
        videoState = .none
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        lastFailureAt = .now
        log.info("No native ad for \(self.placement.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
    }
}

// MARK: - NativeAdDelegate

extension NativeAdSlot: NativeAdDelegate {

    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        log.debug("Impression: \(self.placement.rawValue, privacy: .public)")
    }

    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        log.debug("Click: \(self.placement.rawValue, privacy: .public)")
    }
}

// MARK: - VideoControllerDelegate

extension NativeAdSlot: VideoControllerDelegate {

    func videoControllerDidPlayVideo(_ videoController: VideoController) {
        videoState = .playing
    }

    func videoControllerDidPauseVideo(_ videoController: VideoController) {
        videoState = .paused
    }

    func videoControllerDidEndVideoPlayback(_ videoController: VideoController) {
        videoState = .ended
    }
}

// MARK: - Cache

/// Keeps one slot per placement for the life of the app.
@MainActor
final class NativeAdCache {

    static let shared = NativeAdCache()

    private var slots: [AdPlacement: NativeAdSlot] = [:]

    private init() {}

    func slot(for placement: AdPlacement) -> NativeAdSlot {
        if let existing = slots[placement] { return existing }
        let slot = NativeAdSlot(placement: placement)
        slots[placement] = slot
        return slot
    }

    func clearAll() {
        slots.values.forEach { $0.clear() }
    }
}
