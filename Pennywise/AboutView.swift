//
//  AboutView.swift
//  Pennywise
//

import SwiftUI

@MainActor
struct AboutView: View {
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var consent = AdsConsentManager.shared
    @AppStorage(AdsConfiguration.classroomModeKey) private var classroomMode = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        PennyScreenBackground(
            title: "About this app",
            subtitle: "Pennywise helps you see what happens when the penny disappears: how rounding works, how much coins cost, and who might feel the changes most."
        ) {
            VStack(alignment: .leading, spacing: 20) {
                overviewCard
                whatYouCanDoCard
                SponsoredCard(.about)
                forTeachersCard
                dataSourcesCard
                privacyCard
                versionCard
            }
        }
        .loadsSponsoredCard(.about)
    }

    // MARK: - Cards

    private var overviewCard: some View {
        PennyCard(title: "Why Pennywise exists") {
            VStack(alignment: .leading, spacing: 8) {
                Text("The debate over the penny is a small doorway into bigger ideas: how money is made, how prices are set, and how tiny changes can feel for real people.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                BulletPoint(text: "Turns Mint and rounding data into simple visuals.")
                BulletPoint(text: "Shows how cash rounding can help or hurt different shoppers.")
                BulletPoint(text: "Supports classroom discussions about fairness and public choices.")
            }
        }
    }

    private var whatYouCanDoCard: some View {
        PennyCard(title: "What you can do here") {
            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Test how different rounding rules change a typical purchase.")
                BulletPoint(text: "See how much it costs to produce pennies in recent years.")
                BulletPoint(text: "Read clear explanations of arguments for and against keeping the penny.")
                BulletPoint(text: "Record a local vote on this device and see how opinions are split.")
            }
        }
    }

    private var forTeachersCard: some View {
        PennyCard(title: "Using Pennywise in class") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pennywise is designed to work well on a projector or tablet in the classroom.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                BulletPoint(text: "Use the rounding simulator as a live number line for money problems.")
                BulletPoint(text: "Pair the economics tab with short writing prompts or mini-debates.")
                BulletPoint(text: "Invite students to explain which rounding rule feels fairest and why.")

                Text("There are no accounts, logins, or paywalls, so you can move straight into teaching. Turn on Classroom mode (below) to hide sponsored cards.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .padding(.top, 6)
            }
        }
    }

    private var dataSourcesCard: some View {
        PennyCard(title: "Where the numbers come from") {
            VStack(alignment: .leading, spacing: 8) {
                Text("The cost and production figures in Pennywise are drawn from:")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                BulletPoint(text: "U.S. Mint annual reports for recent years, including the 2024 report that lists a 3.7¢ cost per penny.")
                BulletPoint(text: "Central-bank and academic work on coin reforms and rounding rules.")
                BulletPoint(text: "Public reporting that summarizes how often pennies are used today.")

                Text("Values in the app may be rounded slightly for clarity, but they stay close to the published figures so students can trust the scale of what they see.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .padding(.top, 6)
            }
        }
    }

    private var privacyCard: some View {
        PennyCard(title: "Privacy, ads, and offline use") {
            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Core tools work offline after installation, which fits classrooms with limited or filtered internet access.")
                BulletPoint(text: "Your rounding journal and local votes are stored only on this device and are not synced to a server.")
                BulletPoint(text: "The app does not require personal accounts or student logins.")
                BulletPoint(text: "A few screens show one clearly labeled “Sponsored” card from Google AdMob. Ads are limited to general-audience content and never appear on the Learn & Teach screens.")
                BulletPoint(text: "Ads are only requested after the privacy choices required where you live, and personalized ads are only used if you allow tracking.")

                Toggle(isOn: $classroomMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Classroom mode")
                            .font(.subheadline.bold())
                        Text("Hides every sponsored card on this device — ideal for projectors and student tablets.")
                            .font(.footnote)
                            .foregroundColor(PennyTheme.secondaryText(scheme))
                    }
                }
                .tint(PennyTheme.accentCopper)
                .padding(.top, 6)

                if consent.isPrivacyOptionsRequired {
                    Button {
                        Task { await consent.presentPrivacyOptions() }
                    } label: {
                        Label("Privacy choices", systemImage: "hand.raised")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(PennyTheme.accentCopper)
                }

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Tracking permission in Settings", systemImage: "gearshape")
                        .font(.footnote.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .tint(PennyTheme.accentCopper)
            }
        }
    }

    private var versionCard: some View {
        PennyCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App version")
                        .font(.caption)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                    Text("\(appVersion) (\(buildNumber))")
                        .font(.footnote.monospacedDigit())
                        .foregroundColor(PennyTheme.primaryText(scheme))
                }
                Spacer()
                Text("Thank you for exploring the penny debate with this app, especially if you are sharing it with students or family.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
