//
//  AdsConfigurationTests.swift
//  PennywiseTests
//
//  Checks ad-unit resolution and the placement rules that keep
//  sponsored cards off classroom screens and out of Classroom mode.
//

import Testing
@testable import Pennywise

@MainActor
struct AdsConfigurationTests {

    @Test func placementKeyWinsOverSharedKey() {
        let info: [String: Any] = [
            "PennyNativeAdUnitID": "ca-app-pub-1/shared",
            "PennyNativeAdUnitID_Economics": "ca-app-pub-1/economics"
        ]
        #expect(AdsConfiguration.resolvedNativeAdUnitID(for: .economics, info: info) == "ca-app-pub-1/economics")
        #expect(AdsConfiguration.resolvedNativeAdUnitID(for: .about, info: info) == "ca-app-pub-1/shared")
    }

    @Test func emptyOrUnexpandedValuesFallBackToTestUnit() {
        let info: [String: Any] = [
            "PennyNativeAdUnitID": "$(PENNY_NATIVE_AD_UNIT_ID)",
            "PennyNativeAdUnitID_Journal": "   "
        ]
        #expect(AdsConfiguration.resolvedNativeAdUnitID(for: .journal, info: info)
                == AdsConfiguration.testNativeAdUnitID)
        #expect(AdsConfiguration.resolvedNativeAdUnitID(for: .journal, info: nil)
                == AdsConfiguration.testNativeAdUnitID)
    }

    @Test func detectsTestIDs() {
        let production: [String: Any] = [
            "GADApplicationIdentifier": "ca-app-pub-1111~2222",
            "PennyNativeAdUnitID": "ca-app-pub-1111/3333"
        ]
        #expect(AdsConfiguration.usesTestIDs(info: production) == false)

        var testApp = production
        testApp["GADApplicationIdentifier"] = AdsConfiguration.testApplicationIdentifier
        #expect(AdsConfiguration.usesTestIDs(info: testApp))

        var testUnit = production
        testUnit["PennyNativeAdUnitID_About"] = AdsConfiguration.testNativeVideoAdUnitID
        #expect(AdsConfiguration.usesTestIDs(info: testUnit))
    }

    @Test func classroomModeAndConsentBlockAds() {
        for placement in AdPlacement.allCases {
            #expect(AdsConfiguration.shouldShowAd(at: placement, classroomMode: false, canRequestAds: true))
            #expect(!AdsConfiguration.shouldShowAd(at: placement, classroomMode: true, canRequestAds: true))
            #expect(!AdsConfiguration.shouldShowAd(at: placement, classroomMode: false, canRequestAds: false))
        }
    }

    @Test func everyPlacementHasItsOwnInfoKey() {
        let keys = Set(AdPlacement.allCases.map(\.infoPlistKey))
        #expect(keys.count == AdPlacement.allCases.count)
    }
}
