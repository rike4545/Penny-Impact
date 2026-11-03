# Penny Impact

Penny Impact is an educational iOS app exploring cash rounding, everyday impact, the economics of the penny, and business tools.

## AdMob integration

- Google Mobile Ads SDK via Swift Package Manager.
- UMP consent is refreshed on every app launch.
- The SDK starts only after UMP reports that ad requests are permitted.
- Native ads are displayed only on the Support screen and are clearly labelled.
- Debug builds use Google's official native test ad unit: `ca-app-pub-3940256099942544/3986624511`.
- Release builds use the configured native ad unit: `ca-app-pub-9917450718827221/7231328493`.
- AdMob application ID: `ca-app-pub-9917450718827221~5782515458`.
- No ATT prompt or IDFA-dependent Firebase Analytics is added.

## Before release

1. Confirm the app and ad unit are active in AdMob.
2. Configure UMP privacy messages in AdMob Privacy & messaging for the regions served.
3. Publish a privacy policy that accurately describes Google Mobile Ads and UMP data processing.
4. Complete App Store privacy disclosures.
5. Test on a physical device registered as an AdMob test device; do not click live ads.
6. Confirm ad requests and impressions in AdMob reporting after its reporting delay.

A successful SDK build proves integration, not that the AdMob account is approved or that production inventory is available. A live impression must be confirmed in AdMob reporting.
