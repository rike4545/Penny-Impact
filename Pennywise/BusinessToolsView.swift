//
//  BusinessToolsView.swift
//  Pennywise
//
//  Created by Bryan on 12/2/25.
//


// BusinessToolsView.swift
// For small businesses / cashiers

import SwiftUI

struct BusinessToolsView: View {
    @Environment(\.colorScheme) private var scheme

    @State private var roundingFavorCustomer: Bool = true
    @State private var showCharityExample: Bool = true

    var body: some View {
        PennyScreenBackground(
            title: "For Businesses",
            subtitle: "Design a rounding policy, train staff, and communicate clearly with customers when pennies go away."
        ) {
            VStack(alignment: .leading, spacing: 20) {
                policyDesigner
                signageIdeas
                SponsoredCard(.business)
                trainingCard
            }
        }
        .loadsSponsoredCard(.business)
    }

    private var policyDesigner: some View {
        PennyCard(title: "Rounding policy designer") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $roundingFavorCustomer) {
                    Text("Round in the customer’s favor when in doubt")
                        .font(.subheadline)
                }

                Toggle(isOn: $showCharityExample) {
                    Text("Round up and donate the extra cents to charity")
                        .font(.subheadline)
                }

                Divider()

                Text("Example policy")
                    .font(.caption.bold())
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                Text(examplePolicyText)
                    .font(.footnote)
                    .foregroundColor(PennyTheme.primaryText(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var signageIdeas: some View {
        PennyCard(title: "Customer signage") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Use simple signs near the register so customers know what’s happening:")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                VStack(alignment: .leading, spacing: 8) {
                    SignExample(text: "We’ve retired the penny. Cash totals are rounded to the nearest 5¢ — usually just a cent or two.")
                    SignExample(text: "When rounding could go either way, we round in your favor.")
                    if showCharityExample {
                        SignExample(text: "Each day, rounded-up pennies are donated to a local charity.")
                    }
                }
            }
        }
    }

    private var trainingCard: some View {
        PennyCard(title: "Quick staff training") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Make sure cashiers are comfortable with rounding and how to explain it in one sentence.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                BulletPoint(text: "Practice a few examples: $4.21, $8.63, $12.99.")
                BulletPoint(text: "Keep explanations short and calm: “We round to the nearest 5 cents since we no longer use pennies.”")
                BulletPoint(text: "If a customer is unhappy, staff should be allowed to honor the pre-rounded amount.")
            }
        }
    }

    private var examplePolicyText: String {
        var parts: [String] = []

        parts.append("We no longer use pennies in cash transactions.")
        parts.append("Totals ending in 1–2¢ are rounded down to 0¢; 3–4¢ are rounded up to 5¢.")

        if roundingFavorCustomer {
            parts.append("If rounding could reasonably go either way, we choose the option that benefits the customer.")
        }

        if showCharityExample {
            parts.append("On days when rounding adds up in our favor overall, we donate the difference to a local charity.")
        }

        return parts.joined(separator: " ")
    }
}

struct SignExample: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "quote.bubble")
                .font(.caption)
                .opacity(0.7)
                .padding(.top, 2)
            Text(text)
                .font(.footnote)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
