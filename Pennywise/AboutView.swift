//
//  AboutView.swift
//  Pennywise
//

import SwiftUI

@MainActor
struct AboutView: View {
    @Environment(\.colorScheme) private var scheme

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
                forTeachersCard
                dataSourcesCard
                privacyCard
                versionCard
            }
        }
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

                Text("There are no accounts, logins, or paywalls, so you can move straight into teaching.")
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
        PennyCard(title: "Privacy and offline use") {
            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "The rounding, learning, and business tools do not require accounts or student logins.")
                BulletPoint(text: "Local votes on the penny are stored only on this device and are not synced to a Pennywise account.")
                BulletPoint(text: "A clearly labelled Google native advertisement may appear on the Support screen only.")

                Text("The advertising SDK may process device, diagnostic, and ad-interaction information. Google's consent tools manage consent where required, and ad requests wait until the SDK permits them. Review the app's published privacy policy and App Store privacy disclosures for the complete details.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .padding(.top, 6)
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
