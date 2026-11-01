//
//  SponsoredCard.swift
//  Pennywise
//
//  A native ad that looks and sits like any other Penny card:
//  same rounded surface, stroke, shadow, Avenir type and copper accent —
//  but always clearly labeled "Sponsored", with AdChoices in the top-right
//  corner and the call-to-action at the bottom, far apart.
//
//  Media (image or video) lives in a fixed 16:9 frame that is never
//  smaller than 120 × 120 pt, so the card height never jumps around.
//

import SwiftUI
import GoogleMobileAds

// MARK: - SwiftUI entry points

/// Drop between two cards on an ad-eligible screen. Renders nothing
/// (and takes no space) until an ad has actually loaded.
struct SponsoredCard: View {
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var consent = AdsConsentManager.shared
    @ObservedObject private var slot: NativeAdSlot
    @AppStorage(AdsConfiguration.classroomModeKey) private var classroomMode = false

    private let placement: AdPlacement

    init(_ placement: AdPlacement) {
        self.placement = placement
        self.slot = NativeAdCache.shared.slot(for: placement)
    }

    private var isAllowed: Bool {
        AdsConfiguration.shouldShowAd(
            at: placement,
            classroomMode: classroomMode,
            canRequestAds: consent.canRequestAds
        )
    }

    var body: some View {
        if isAllowed, let ad = slot.nativeAd {
            NativeAdCardView(nativeAd: ad)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(PennyTheme.cardGradient(scheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(PennyTheme.cardStroke(scheme))
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: PennyTheme.cardShadow(scheme), radius: 20, x: 0, y: 12)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Sponsored")
                .transition(.opacity)
        }
    }
}

extension View {
    /// Attach to an ad-eligible screen so its slot loads when the screen
    /// appears (and is released if Classroom mode is turned on).
    func loadsSponsoredCard(_ placement: AdPlacement) -> some View {
        modifier(SponsoredCardLoader(placement: placement))
    }
}

private struct SponsoredCardLoader: ViewModifier {
    @ObservedObject private var consent = AdsConsentManager.shared
    @AppStorage(AdsConfiguration.classroomModeKey) private var classroomMode = false

    let placement: AdPlacement

    private var trigger: Bool {
        consent.isSDKStarted && AdsConfiguration.shouldShowAd(
            at: placement,
            classroomMode: classroomMode,
            canRequestAds: consent.canRequestAds
        )
    }

    func body(content: Content) -> some View {
        content
            .task(id: trigger) {
                let slot = NativeAdCache.shared.slot(for: placement)
                if trigger {
                    slot.loadIfNeeded()
                } else if classroomMode {
                    slot.clear()
                }
            }
    }
}

// MARK: - UIKit bridge

private struct NativeAdCardView: UIViewRepresentable {
    let nativeAd: NativeAd

    func makeUIView(context: Context) -> PennyNativeAdView {
        PennyNativeAdView()
    }

    func updateUIView(_ uiView: PennyNativeAdView, context: Context) {
        uiView.bind(nativeAd)
    }

    func sizeThatFits(_ proposal: ProposedViewSize,
                      uiView: PennyNativeAdView,
                      context: Context) -> CGSize? {
        var width = proposal.width ?? 340
        if !width.isFinite || width <= 0 { width = 340 }
        let fitted = uiView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        return CGSize(width: width, height: ceil(fitted.height))
    }
}

/// Programmatic `NativeAdView` (no xib) styled with PennyTheme.
final class PennyNativeAdView: NativeAdView {

    private let badgeLabel = PaddedLabel()
    private let iconImageView = UIImageView()
    private let headlineLabel = UILabel()
    private let advertiserLabel = UILabel()
    private let bodyLabel = UILabel()
    private let adMediaView = MediaView()
    private let mediaFrame = UIView()
    private let detailLabel = UILabel()
    private let ctaButton = UIButton(configuration: .filled())
    private let footer = UIStackView()

    private weak var boundAd: NativeAd?

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildLayout()
    }

    // MARK: Binding

    func bind(_ ad: NativeAd) {
        guard boundAd !== ad else { return }
        boundAd = ad

        headlineLabel.text = ad.headline

        advertiserLabel.text = ad.advertiser
        advertiserLabel.isHidden = (ad.advertiser ?? "").isEmpty

        bodyLabel.text = ad.body
        bodyLabel.isHidden = (ad.body ?? "").isEmpty

        iconImageView.image = ad.icon?.image
        iconImageView.isHidden = ad.icon?.image == nil

        adMediaView.mediaContent = ad.mediaContent

        let details = [ad.starRating.map { String(format: "★ %.1f", $0.doubleValue) },
                       ad.store, ad.price]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        detailLabel.text = details.joined(separator: "  ·  ")
        detailLabel.isHidden = details.isEmpty

        var config = ctaButton.configuration
        config?.title = ad.callToAction
        ctaButton.configuration = config
        ctaButton.isHidden = (ad.callToAction ?? "").isEmpty
        footer.isHidden = detailLabel.isHidden && ctaButton.isHidden

        // Register assets, then hand the ad over — this makes it clickable.
        headlineView = headlineLabel
        advertiserView = advertiserLabel.isHidden ? nil : advertiserLabel
        bodyView = bodyLabel.isHidden ? nil : bodyLabel
        iconView = iconImageView.isHidden ? nil : iconImageView
        mediaView = adMediaView
        starRatingView = nil
        storeView = nil   // detail line mixes store/rating/price; shown as plain text
        priceView = nil
        callToActionView = ctaButton.isHidden ? nil : ctaButton

        nativeAd = ad
    }

    // MARK: Layout

    private func buildLayout() {
        backgroundColor = .clear

        // "Sponsored" badge — always visible, matches StatPill styling.
        badgeLabel.text = "Sponsored"
        badgeLabel.font = Self.font("AvenirNext-DemiBold", 11, .caption2)
        badgeLabel.textColor = Self.copper
        badgeLabel.backgroundColor = Self.copper.withAlphaComponent(0.12)
        badgeLabel.layer.cornerRadius = 9
        badgeLabel.layer.masksToBounds = true
        badgeLabel.insets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
        badgeLabel.textAlignment = .center
        badgeLabel.setContentHuggingPriority(.required, for: .horizontal)
        badgeLabel.accessibilityLabel = "Sponsored content"

        let badgeRow = UIStackView(arrangedSubviews: [badgeLabel, UIView()])
        badgeRow.axis = .horizontal

        // Icon + headline + advertiser
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.layer.cornerRadius = 10
        iconImageView.layer.masksToBounds = true
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 40),
            iconImageView.heightAnchor.constraint(equalToConstant: 40)
        ])

        headlineLabel.font = Self.font("AvenirNext-DemiBold", 17, .headline)
        headlineLabel.textColor = Self.primaryText
        headlineLabel.numberOfLines = 2

        advertiserLabel.font = Self.font("AvenirNext-Regular", 12, .caption1)
        advertiserLabel.textColor = Self.secondaryText

        let titles = UIStackView(arrangedSubviews: [headlineLabel, advertiserLabel])
        titles.axis = .vertical
        titles.spacing = 2

        let header = UIStackView(arrangedSubviews: [iconImageView, titles])
        header.axis = .horizontal
        header.spacing = 12
        header.alignment = .center

        bodyLabel.font = Self.font("AvenirNext-Regular", 14, .footnote)
        bodyLabel.textColor = Self.secondaryText
        bodyLabel.numberOfLines = 3

        // Fixed-size media frame: 16:9, never under 120 pt tall.
        // MediaView aspect-fits inside, so any creative shape works
        // without the card resizing.
        mediaFrame.backgroundColor = Self.copper.withAlphaComponent(0.06)
        mediaFrame.layer.cornerRadius = 12
        mediaFrame.layer.masksToBounds = true
        mediaFrame.translatesAutoresizingMaskIntoConstraints = false

        adMediaView.contentMode = .scaleAspectFit
        adMediaView.translatesAutoresizingMaskIntoConstraints = false
        mediaFrame.addSubview(adMediaView)

        let aspect = mediaFrame.heightAnchor.constraint(equalTo: mediaFrame.widthAnchor, multiplier: 9.0 / 16.0)
        aspect.priority = .required - 1
        NSLayoutConstraint.activate([
            aspect,
            mediaFrame.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            mediaFrame.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            adMediaView.topAnchor.constraint(equalTo: mediaFrame.topAnchor),
            adMediaView.bottomAnchor.constraint(equalTo: mediaFrame.bottomAnchor),
            adMediaView.leadingAnchor.constraint(equalTo: mediaFrame.leadingAnchor),
            adMediaView.trailingAnchor.constraint(equalTo: mediaFrame.trailingAnchor)
        ])

        // Footer: store / rating / price on the left, CTA on the right.
        detailLabel.font = Self.font("AvenirNext-Regular", 12, .caption1)
        detailLabel.textColor = Self.secondaryText
        detailLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        var cta = UIButton.Configuration.filled()
        cta.baseBackgroundColor = Self.copper
        cta.baseForegroundColor = .white
        cta.cornerStyle = .capsule
        cta.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        cta.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Self.font("AvenirNext-DemiBold", 14, .subheadline)
            return outgoing
        }
        ctaButton.configuration = cta
        // The SDK handles taps; the button must not swallow them.
        ctaButton.isUserInteractionEnabled = false
        ctaButton.setContentHuggingPriority(.required, for: .horizontal)
        ctaButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        footer.addArrangedSubview(detailLabel)
        footer.addArrangedSubview(ctaButton)
        footer.axis = .horizontal
        footer.spacing = 12
        footer.alignment = .center

        for label in [badgeLabel, headlineLabel, advertiserLabel, bodyLabel, detailLabel] {
            label.adjustsFontForContentSizeCategory = true
        }

        let stack = UIStackView(arrangedSubviews: [badgeRow, header, bodyLabel, mediaFrame, footer])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(8, after: badgeRow)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])

        // Keep the badge row clear of the AdChoices icon (~20 pt).
        badgeRow.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 28)
        badgeRow.isLayoutMarginsRelativeArrangement = true
    }

    // MARK: Theme bridge

    private static let copper = UIColor(red: 0.78, green: 0.42, blue: 0.18, alpha: 1)

    private static let primaryText = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? .white
            : UIColor(red: 0.12, green: 0.10, blue: 0.09, alpha: 1)
    }

    private static let secondaryText = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.75)
            : UIColor.black.withAlphaComponent(0.60)
    }

    private static func font(_ name: String, _ size: CGFloat,
                             _ style: UIFont.TextStyle) -> UIFont {
        let base = UIFont(name: name, size: size) ?? .preferredFont(forTextStyle: style)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base)
    }
}

/// UILabel with internal padding, used for the "Sponsored" badge.
private final class PaddedLabel: UILabel {
    var insets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }
}
