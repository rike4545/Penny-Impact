//
//  PennyNativeAdCard.swift
//  Penny Impact
//
//  A clearly labelled native ad shown only on the Support screen.
//

import SwiftUI
import UIKit
import GoogleMobileAds

@MainActor
final class PennyNativeAdModel: NSObject, ObservableObject, NativeAdLoaderDelegate, NativeAdDelegate {
    @Published private(set) var ad: NativeAd?
    @Published private(set) var loadError: String?
    @Published private(set) var isLoading = false

    private var loader: AdLoader?

    private var adUnitID: String {
        #if DEBUG
        // Google's official native test unit. Never generate live traffic in Debug.
        return "ca-app-pub-3940256099942544/3986624511"
        #else
        return "ca-app-pub-9917450718827221/7231328493"
        #endif
    }

    func load() {
        guard loader == nil, ad == nil, !isLoading else { return }
        isLoading = true
        loadError = nil

        let rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController

        let requestLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: nil
        )
        loader = requestLoader
        requestLoader.delegate = self
        requestLoader.load(Request())
    }

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        isLoading = false
        ad = nativeAd
        loadError = nil
        nativeAd.delegate = self
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        isLoading = false
        loadError = error.localizedDescription
        loader = nil
        NSLog("Penny Impact: native ad request failed: %@", error.localizedDescription)
    }
}

@MainActor
struct PennyNativeAdCard: View {
    @StateObject private var model = PennyNativeAdModel()
    @ObservedObject private var consent = AdConsentManager.shared

    var body: some View {
        Group {
            if consent.canRequestAds {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Advertisement")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let ad = model.ad {
                        PennyNativeAdView(ad: ad)
                            .frame(minHeight: 250)
                            .padding(12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    } else if model.loadError != nil {
                        Button {
                            model.load()
                        } label: {
                            Label("Ad unavailable — try again", systemImage: "arrow.clockwise")
                                .font(.footnote.weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 72)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        ProgressView("Loading sponsored content…")
                            .frame(maxWidth: .infinity, minHeight: 72)
                    }
                }
                .accessibilityElement(children: .contain)
            }
        }
        .task {
            if consent.canRequestAds {
                model.load()
            }
        }
        .onChange(of: consent.canRequestAds) { _, allowed in
            if allowed {
                model.load()
            }
        }
    }
}

private struct PennyNativeAdView: UIViewRepresentable {
    let ad: NativeAd

    func makeUIView(context: Context) -> NativeAdView {
        let adView = NativeAdView()
        adView.backgroundColor = .clear

        let headline = UILabel()
        headline.font = .preferredFont(forTextStyle: .headline)
        headline.numberOfLines = 2

        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.clipsToBounds = true
        icon.layer.cornerRadius = 8
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 48),
            icon.heightAnchor.constraint(equalToConstant: 48)
        ])

        let titleRow = UIStackView(arrangedSubviews: [icon, headline])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 10

        let media = MediaView()
        media.contentMode = .scaleAspectFit
        media.clipsToBounds = true
        media.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            media.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])

        let body = UILabel()
        body.font = .preferredFont(forTextStyle: .subheadline)
        body.numberOfLines = 3
        body.textColor = .secondaryLabel

        let callToAction = UIButton(type: .system)
        callToAction.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        callToAction.backgroundColor = .systemBlue
        callToAction.setTitleColor(.white, for: .normal)
        callToAction.layer.cornerRadius = 9
        callToAction.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        callToAction.isUserInteractionEnabled = false

        let stack = UIStackView(arrangedSubviews: [titleRow, media, body, callToAction])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            stack.topAnchor.constraint(equalTo: adView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: adView.bottomAnchor)
        ])

        adView.headlineView = headline
        adView.iconView = icon
        adView.mediaView = media
        adView.bodyView = body
        adView.callToActionView = callToAction
        return adView
    }

    func updateUIView(_ adView: NativeAdView, context: Context) {
        (adView.headlineView as? UILabel)?.text = ad.headline
        (adView.bodyView as? UILabel)?.text = ad.body
        adView.bodyView?.isHidden = ad.body == nil

        if let iconView = adView.iconView as? UIImageView {
            iconView.image = ad.icon?.image
            iconView.isHidden = ad.icon == nil
        }

        if let button = adView.callToActionView as? UIButton {
            button.setTitle(ad.callToAction, for: .normal)
            button.isHidden = ad.callToAction == nil
        }

        adView.mediaView?.mediaContent = ad.mediaContent
        adView.nativeAd = ad
    }
}
