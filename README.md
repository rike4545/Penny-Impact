# Penny Impact

**Penny Impact** (project name *Pennywise*) is a SwiftUI app for iPhone and iPad that explains what happens when the U.S. penny goes away: how cash totals get rounded to the nearest 5¢, what that means for shoppers and businesses, what pennies cost to make, and how to teach all of it in a classroom.

- **Platforms:** iPhone and iPad, iOS 26.1+
- **Bundle ID:** `Me.Pennywise` · display name **Penny Impact**
- **Category:** Finance
- **Accounts:** none — no logins, no paywalls
- **Monetization:** one clearly labeled *Sponsored* native ad card on selected screens (Google AdMob), with a Classroom mode that turns ads off

---

## Features

| Section | What it does | Sponsored card |
|---|---|---|
| **Everyday Impact** | Model a typical purchase: checkout total, trips per week, cash share and rounding rule (nearest 5¢, always up, always down). Shows per-purchase, monthly and yearly effect in plain English. Links to the **Receipt playground**, which builds a multi-item bill and rounds the whole total. | Yes — between *Estimated effect* and *Dig deeper* |
| **Journal & Coach** | Log real cash purchases, see total saved vs. overpaid and the net result. Entries stay on the device (swipe to delete, or clear all). | Yes — below your entries |
| **For Businesses** | Rounding-policy designer (round in the customer's favor, round-up-for-charity), ready-to-use register signage and quick staff-training points. | Yes — between *Customer signage* and *Quick staff training* |
| **Learn & Teach** | Classroom-ready explanations: what's happening to the penny, rounding as a math lesson, a mini debate kit and teacher ideas. | **Never** |
| **Economics** | U.S. Mint cost-per-penny data (2022–2024, including the 3.7¢ 2024 figure) with a year picker and trend chart, rounding fairness, arguments for keeping the coin, who wins and loses, and an on-device opinion poll. | Yes — between *Reasons to keep* and *Who wins* |
| **About** | Purpose, data sources, privacy, **Classroom mode**, privacy choices and version info. *Support* (toolbar) offers App Store review and free ways to help. | Yes — after *What you can do here* (none on Support) |

The app adapts its shell to the device: a **tab bar** on iPhone (compact width) and a **sidebar** on iPad (regular width).

### Also in the codebase

- `TeacherWorksheetView` — worksheet generator (grade band, rule mix, word problems, answer key)
- `RoundingInsightsView` — rule-based "coach" that reads the journal (customer / store / teacher perspectives, what-if cash slider)

Both screens are built but **not yet linked** from navigation. Add a `NavigationLink` from Learn & Teach and Journal respectively to ship them. Keep the worksheet ad-free — it is a classroom screen.

---

## Project structure

```
Pennywise/
├── PennywiseApp.swift             App entry; runs consent → ATT → ads SDK when the app becomes active
├── PennyTab.swift                 Sections + RootTabView (picks phone or tablet shell)
├── PhoneTabShell.swift            iPhone tab bar
├── TabletSidebarShell.swift       iPad sidebar
├── PennyTheme 2.swift             Copper/mint colors, Avenir type, UIKit appearance
├── PennyScreenBackground.swift    Screen scaffold, PennyCard, StatPill, animated backdrop
├── BulletPoint.swift
├── EverydayImpactView.swift       ReceiptRoundingPlaygroundView.swift
├── RoundingLogEntry.swift         Journal model, UserDefaults store, journal screens
├── RoundingInsightsView.swift     RoundingRule.swift  RoundingRule+Math.swift*
├── BusinessToolsView.swift        LearnTeachView.swift  TeacherWorksheetView.swift
├── EconomicsView 2.swift          MintStats.swift  PennyOpinionChoice 2.swift
├── AboutView.swift                SupportView.swift
├── Ads/
│   ├── AdsConfiguration.swift     Ad unit IDs per placement, eligible screens, Classroom mode key
│   ├── AdsConsentManager.swift    UMP consent → ATT prompt → Google Mobile Ads start
│   ├── NativeAdSlot.swift         One native ad per placement (image + video), cache, refresh, video events
│   └── SponsoredCard.swift        SwiftUI card + programmatic NativeAdView styled like PennyCard
├── Info.plist                     Ad keys merged with Xcode's generated Info.plist
└── PrivacyInfo.xcprivacy          App privacy manifest (UserDefaults: CA92.1)
PennywiseTests/                    Swift Testing unit tests (incl. AdsConfigurationTests)
PennywiseUITests/
```
\* `RoundingRule+Math.swift` is excluded from the target in the project file.

The `Pennywise` folder is a **file-system synchronized group** (Xcode 16+): any new file dropped in the folder is compiled automatically. `Info.plist` is listed as a membership exception so it is processed, not copied.

---

## Building

1. Xcode **26.2 or later** (required by Google Mobile Ads 13.4+).
2. Open `Pennywise.xcodeproj`. Xcode resolves two Swift packages:
   - `swift-package-manager-google-mobile-ads` — up to next major from **13.11.0**
   - `swift-package-manager-google-user-messaging-platform` — up to next major from **3.1.0**
3. Select the **Pennywise** scheme and run on an iOS 26.1+ simulator or device.
4. Run tests with **⌘U** (`AdsConfigurationTests` covers ad-unit resolution, test-ID detection and the Classroom-mode/consent rules).

Debug and Release both ship with **Google's public test IDs**, so ads render as labeled test ads until you add your own (see below). Release builds log a `fault` to the console while test IDs are still set.

---

## Native ads

### How they work

1. **Launch flow** (`AdsConsentManager`, each time the app becomes active)
   1. UMP `requestConsentInfoUpdate` → `ConsentForm.loadAndPresentIfRequired` (GDPR / US state messages when they apply)
   2. App Tracking Transparency prompt — only if still `.notDetermined`
   3. `MobileAds.shared.start` — only when `ConsentInformation.shared.canRequestAds` is true, with `maxAdContentRating = .general`

   Consent cached from a previous launch is used immediately, so returning users see ads without waiting on the network. If the network is down, the app falls back to cached consent and never blocks the UI.

2. **Loading** (`NativeAdSlot`) — each eligible screen has `.loadsSponsoredCard(.placement)`, which requests one ad when the screen appears. Ads are cached per placement (no new request on every tab switch), refreshed after ~55 minutes, and failures back off for 60 seconds.
   - Media aspect ratio is left at **any**, so image and video creatives of every shape compete.
   - Video starts **muted**; play / pause / end events are tracked via `VideoController`.
   - AdChoices is requested in the **top-right** corner; the call-to-action sits at the **bottom** of the card, so they never overlap.

3. **Rendering** (`SponsoredCard`) — a programmatic `NativeAdView` with the same rounded surface, stroke, shadow, Avenir fonts and copper accent as every other `PennyCard`, so it reads as part of the feed. It is always labeled **Sponsored**. Media sits in a fixed 16:9 frame that is never smaller than 120 × 120 pt (required for video), so the card height doesn't jump. The CTA button has user interaction disabled so the SDK receives the tap. Until an ad loads, the card takes no space at all.

### Where ads never appear

Learn & Teach, the teacher worksheet and Support. When **Classroom mode** (About → Privacy, ads, and offline use) is on, no ads are requested anywhere on that device and loaded ads are released.

### Permissions and privacy keys

| Item | Where | Value |
|---|---|---|
| `GADApplicationIdentifier` | `Info.plist` | `$(GAD_APPLICATION_IDENTIFIER)` |
| `SKAdNetworkItems` | `Info.plist` | Google's full list of 50 identifiers |
| `NSUserTrackingUsageDescription` | build setting `INFOPLIST_KEY_…` | Explains the sponsored card and that the app works either way |
| `PennyNativeAdUnitID[_Placement]` | `Info.plist` | From the build settings below |
| Privacy manifest | `PrivacyInfo.xcprivacy` | No tracking by app code; UserDefaults reason CA92.1. The Google SDKs include their own manifests. |
| Privacy choices | About screen | *Privacy choices* button appears when UMP says it's required; *Tracking permission in Settings* link always available |

### Going live — checklist

1. **AdMob app** — create the iOS app in AdMob and note its app ID.
2. **One native ad unit per placement** — create five *Native advanced* units (Impact, Journal, Business, Economics, About) so each shows separately in reports. In each unit's advanced settings, allow **Video** as a media type.
3. **Build settings** (Pennywise target → Build Settings → User-Defined), Release configuration:

   | Setting | Value |
   |---|---|
   | `GAD_APPLICATION_IDENTIFIER` | `ca-app-pub-XXXXXXXX~YYYYYYYY` |
   | `PENNY_NATIVE_AD_UNIT_ID_IMPACT` | Impact unit |
   | `PENNY_NATIVE_AD_UNIT_ID_JOURNAL` | Journal unit |
   | `PENNY_NATIVE_AD_UNIT_ID_BUSINESS` | Business unit |
   | `PENNY_NATIVE_AD_UNIT_ID_ECONOMICS` | Economics unit |
   | `PENNY_NATIVE_AD_UNIT_ID_ABOUT` | About unit |
   | `PENNY_NATIVE_AD_UNIT_ID` | Optional shared fallback for any placement left empty |

   Keep Debug on the test IDs. Never click your own live ads.
4. **Privacy & messaging** in AdMob — publish a **GDPR** message and a **US state regulations** message. Optionally add an **IDFA explainer** message; if you do, UMP shows Apple's ATT prompt itself and the app's own ATT call is skipped automatically.
5. **app-ads.txt** — host it on the developer website listed in App Store Connect.
6. **App Store Connect privacy label** — declare the data Google Mobile Ads collects (device ID / advertising data, product interaction, diagnostics; "used for tracking" when ATT is allowed). See Google's *Data disclosure* guide.
7. **Ad content rating** — the code caps ads at *General*; mirror that in AdMob blocking controls (sensitive categories) for a classroom-friendly app.

### Revenue tuning (AdMob console, no code changes)

- **Mediation & bidding:** add bidding networks (e.g. AppLovin, Meta Audience Network, Unity) to the native units instead of AdMob alone. Each needs its adapter package added in Xcode and its SKAdNetwork IDs merged into `Info.plist`.
- **Floors:** use optimized or tiered eCPM floors per unit.
- **Experiments:** AdMob A/B tests (or Firebase A/B Testing) for layout, CTA color and placement.

### Testing ads

- Debug builds use Google's test native unit (`…/3986624511`), which serves image and video test creatives. For video-only checks, temporarily set a placement to `ca-app-pub-3940256099942544/2521693316`.
- To test the EEA consent form, add `DebugSettings` with your device's test identifier and `geography = .EEA` to the `RequestParameters` in `AdsConsentManager.requestConsentInfoUpdate()` — Debug only.
- Reset ATT on a simulator with *Settings → Privacy & Security → Tracking*, or erase the simulator.

---

## Data and privacy

- The journal (`UserDefaults`) and poll votes (`@AppStorage`) are stored only on the device; nothing is synced.
- Mint figures come from U.S. Mint annual reports (2022–2024).
- No accounts, analytics or crash reporting beyond what the Google Mobile Ads SDK collects for ads, and only after consent.
