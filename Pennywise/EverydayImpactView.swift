//
//  EverydayImpactView.swift
//  Pennywise
//
//  Everyday penny-rounding simulator:
//  • Model a “typical” purchase
//  • Mix of cash vs card
//  • Monthly + yearly impact
//  • Quick link to the full receipt playground
//

import SwiftUI

@MainActor
struct EverydayImpactView: View {
    @Environment(\.colorScheme) private var scheme

    // MARK: - User input

    @State private var amountText: String = "12.73"
    @State private var tripsPerWeek: Double = 5
    @State private var cashShare: Double = 0.5
    @State private var selectedRule: RoundingRule = .nearestFive

    // MARK: - Derived values

    /// Parsed purchase amount from the text field.
    private var purchaseAmount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    /// Rounded total for a single cash purchase.
    private var roundedCashTotal: Double {
        roundedTotal(for: purchaseAmount, rule: selectedRule)
    }

    /// Difference for a single cash purchase (can be + or −).
    private var perCashDifference: Double {
        roundToCents(roundedCashTotal - purchaseAmount)
    }

    /// Effective cash purchases per week.
    private var weeklyCashTrips: Double {
        tripsPerWeek * cashShare
    }

    /// Approximate monthly impact (4.3 weeks per month).
    private var monthlyDifference: Double {
        roundToCents(perCashDifference * weeklyCashTrips * 4.3)
    }

    /// Approximate yearly impact.
    private var yearlyDifference: Double {
        roundToCents(monthlyDifference * 12)
    }

    /// Emoji that indicates the direction of impact.
    private var perDiffEmoji: String {
        if perCashDifference > 0 {
            return "⬆️"
        } else if perCashDifference < 0 {
            return "⬇️"
        } else {
            return "⚖️"
        }
    }

    /// Plain-English summary of how big the impact is.
    private var impactSummary: String {
        guard purchaseAmount > 0 else {
            return "Enter a realistic purchase total to see how rounding adds up over time."
        }

        if perCashDifference == 0 || weeklyCashTrips == 0 {
            return "With this pattern of purchases, rounding doesn’t noticeably change what you pay."
        }

        let direction = perCashDifference > 0 ? "pay a bit more" : "save a bit"
        let magnitude = abs(yearlyDifference)

        switch magnitude {
        case 0..<0.25:
            return "You’d \(direction), but only by a few cents per year — basically noise."
        case 0.25..<1:
            return "You’d \(direction) over the course of a year, but the effect is still quite small."
        case 1..<5:
            return "Over a year, you’d \(direction) about \(formattedCurrency(magnitude)), similar to a snack or coffee."
        default:
            return "Over a year, you’d \(direction) around \(formattedCurrency(magnitude)). That’s real money for some budgets."
        }
    }

    // MARK: - Body

    var body: some View {
        PennyScreenBackground(
            title: "Everyday impact",
            subtitle: "Model a typical purchase and see how penny rounding stacks up over time."
        ) {
            VStack(spacing: 16) {
                scenarioCard
                effectCard
                exploreCard
            }
        }
        .toolbarTitleDisplayMode(.inline)
    }

    // MARK: - Cards

    private var scenarioCard: some View {
        PennyCard(title: "Your typical purchase") {
            VStack(alignment: .leading, spacing: 14) {
                // Amount
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average checkout total")
                        .font(.subheadline.bold())

                    HStack {
                        TextField("12.73", text: $amountText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)

                        Text("per visit")
                            .font(.footnote)
                            .foregroundColor(PennyTheme.secondaryText(scheme))
                    }

                    if purchaseAmount <= 0 {
                        Text("Think of a small grocery run, a coffee stop, or a quick lunch.")
                            .font(.footnote)
                            .foregroundColor(PennyTheme.secondaryText(scheme))
                    }
                }

                // Frequency
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("How often?")
                            .font(.subheadline.bold())
                        Spacer()
                        Text("\(Int(tripsPerWeek))× per week")
                            .font(.footnote.monospacedDigit())
                            .foregroundColor(PennyTheme.secondaryText(scheme))
                    }

                    Slider(value: $tripsPerWeek, in: 1...40, step: 1) {
                        Text("Trips per week")
                    }
                }

                // Cash vs card
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("How many are cash?")
                            .font(.subheadline.bold())
                        Spacer()
                        Text("\(Int(cashShare * 100))% cash")
                            .font(.footnote.monospacedDigit())
                            .foregroundColor(PennyTheme.secondaryText(scheme))
                    }

                    Slider(value: $cashShare, in: 0...1, step: 0.05) {
                        Text("Percent paid with cash")
                    }

                    Text("Rounding only happens on the cash portion. Card and digital payments still use the exact total.")
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                }

                // Rounding rule
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rounding rule")
                        .font(.subheadline.bold())

                    Picker("Rounding rule", selection: $selectedRule) {
                        ForEach(RoundingRule.allCases) { rule in
                            Text(rule.rawValue).tag(rule)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(ruleDescription(for: selectedRule))
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var effectCard: some View {
        PennyCard(title: "Estimated effect") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Exact total (per visit)")
                    Spacer()
                    Text(formattedCurrency(purchaseAmount))
                        .font(.headline.monospacedDigit())
                }

                HStack {
                    Text("Cash total after rounding")
                    Spacer()
                    Text(formattedCurrency(roundedCashTotal))
                        .font(.headline.monospacedDigit())
                }

                StatPill(
                    label: "Per cash purchase",
                    value: "\(formattedCurrency(perCashDifference)) \(perDiffEmoji)",
                    icon: "banknote"
                )

                HStack {
                    StatPill(
                        label: "Per month",
                        value: formattedCurrency(monthlyDifference),
                        icon: "calendar"
                    )
                    StatPill(
                        label: "Per year",
                        value: formattedCurrency(yearlyDifference),
                        icon: "calendar.badge.clock"
                    )
                }

                Text(impactSummary)
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
            }
        }
    }

    private var exploreCard: some View {
        PennyCard(title: "Dig deeper") {
            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Try changing the cents in your total and watch how the rounded amount jumps in 5¢ steps.")
                BulletPoint(text: "Set cash to 0% to see how little rounding matters if you almost always pay with card or phone.")

                NavigationLink {
                    ReceiptRoundingPlaygroundView()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Build a full receipt")
                                .font(.subheadline.bold())
                            Text("Add multiple items and see how rounding affects the whole bill.")
                                .font(.footnote)
                                .foregroundColor(PennyTheme.secondaryText(scheme))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.bold())
                            .foregroundColor(PennyTheme.accentCopper)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Apply a rounding rule to a dollar amount, working in cents.
    private func roundedTotal(for value: Double, rule: RoundingRule) -> Double {
        guard value >= 0 else { return value }

        let cents = (value * 100).rounded()
        let nickels: Double

        switch rule {
        case .nearestFive:
            nickels = (cents / 5.0).rounded()
        case .alwaysUp:
            nickels = ceil(cents / 5.0)
        case .alwaysDown:
            nickels = floor(cents / 5.0)
        }

        return nickels * 5.0 / 100.0
    }

    private func ruleDescription(for rule: RoundingRule) -> String {
        switch rule {
        case .nearestFive:
            return "Totals are rounded to the nearest 5¢ — sometimes up, sometimes down."
        case .alwaysUp:
            return "Totals are always rounded up to the next 5¢. The customer never pays less than the exact total."
        case .alwaysDown:
            return "Totals are always rounded down to the previous 5¢, so the customer never pays more than the exact total."
        }
    }

    private func roundToCents(_ value: Double) -> Double {
        let factor = 100.0
        return (value * factor).rounded() / factor
    }

    private func formattedCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}
