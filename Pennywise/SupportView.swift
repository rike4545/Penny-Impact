//
//  SupportView.swift
//  Pennywise
//
//  Ways to support Pennywise without paywalls or fake links.
//

import SwiftUI
import StoreKit

@MainActor
struct SupportView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        PennyScreenBackground(
            title: "Support Pennywise",
            subtitle: "Pennywise is meant to stay simple and classroom-friendly. If you find it useful, here are a few ways to keep it going."
        ) {
            VStack(alignment: .leading, spacing: 20) {
                whySupportCard
                simpleActionsCard
                classroomSupportCard
            }
        }
    }

    // MARK: - Cards

    private var whySupportCard: some View {
        PennyCard(title: "Why support an app about pennies?") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Conversations about small coins open the door to bigger topics: public costs, everyday fairness, and how we handle change at the register.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                BulletPoint(text: "Keeping Pennywise maintained helps teachers and families use current numbers and clear visuals.")
                BulletPoint(text: "Support makes it easier to add new examples and polish over time.")
            }
        }
    }

    private var simpleActionsCard: some View {
        PennyCard(title: "Free ways to help") {
            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Mention the app to a teacher, librarian, or parent who might use it.")
                BulletPoint(text: "Share it with students when you talk about coins, rounding, or inflation.")
                BulletPoint(text: "Leave a kind review in the App Store if you think the app explains things clearly.")

                Button {
                    requestReview()
                } label: {
                    Label("Rate & review in the App Store", systemImage: "star.bubble.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(PennyTheme.accentCopper)
                .padding(.top, 4)
            }
        }
    }

    private var classroomSupportCard: some View {
        PennyCard(title: "If you work in education") {
            VStack(alignment: .leading, spacing: 8) {
                Text("If you are part of a school, library, or community program, you can support Pennywise simply by putting it to work.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                BulletPoint(text: "Include Pennywise as a visual aid in money or civics lessons.")
                BulletPoint(text: "Let colleagues know it is free to use with students and does not require logins.")
                BulletPoint(text: "Share feedback about what helps your learners most, so future updates focus on those pieces.")

                Text("Every classroom or program that uses the app is a form of support, because it turns a small project into something students actually see.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .padding(.top, 6)
            }
        }
    }

    // MARK: - Store review helper

    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}
