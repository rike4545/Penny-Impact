//
//  EconomicsView 2.swift
//  Pennywise
//
//  Created by Bryan on 12/2/25.
//


//
//  EconomicsView.swift
//  Pennywise
//
//  Economics of the penny, wired to MintStatsStore
//  and explicitly using the 3.7¢ 2024 Mint figure.
//

import SwiftUI

@MainActor
struct EconomicsView: View {
    @Environment(\.colorScheme) private var scheme

    @StateObject private var statsStore = MintStatsStore()
    @StateObject private var pollStore  = PennyOpinionStore()

    var body: some View {
        PennyScreenBackground(
            title: "Economics of the Penny",
            subtitle: "See how much it costs to make pennies, who pays for rounding, and why people disagree about keeping the smallest coin."
        ) {
            VStack(alignment: .leading, spacing: 20) {
                mintDataCard
                roundingFairnessCard
                reasonsToKeepCard
                whoWinsCard
                pollCard
            }
        }
    }

    // MARK: - Mint data

    private var mintDataCard: some View {
        PennyCard(title: "Cost to make a penny") {
            VStack(alignment: .leading, spacing: 12) {
                if statsStore.stats.isEmpty {
                    Text("Mint data is temporarily unavailable.")
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                } else {
                    yearPicker

                    if let stat = statsStore.currentStat {
                        mintStatsSummary(for: stat)
                    }

                    miniTrendChart
                }

                Text("Numbers for 2022–2024 are based on the U.S. Mint’s annual reports. In the 2024 report, each penny cost about 3.7 cents to produce and distribute — more than three times its 1¢ face value.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
            }
        }
    }

    private var yearPicker: some View {
        HStack {
            Text("Year")
                .font(.subheadline)
            Spacer()
            Picker("Year", selection: $statsStore.selectedYear) {
                ForEach(statsStore.stats) { stat in
                    Text("\(stat.year)").tag(Optional(stat.year))
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 260)
        }
    }

    private func mintStatsSummary(for stat: MintStats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cost to make 1 penny")
                        .font(.caption)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                    Text(String(format: "$%.3f", stat.unitCostDollars))
                        .font(.title3.bold())
                        .foregroundColor(PennyTheme.accentCopper)
                        .monospacedDigit()
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Face value")
                        .font(.caption)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                    Text("$0.010")
                        .font(.title3.bold())
                        .foregroundColor(PennyTheme.primaryText(scheme))
                        .monospacedDigit()
                }
            }

            // Simple bar comparison between production cost and value
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(PennyTheme.accentCopper.opacity(0.12))
                .frame(height: 18)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        let maxWidth = geo.size.width
                        // Normalize against 5¢ so higher costs don’t overflow.
                        let ratio = min(max(stat.unitCostDollars / 0.05, 0), 1)
                        let costWidth  = maxWidth * ratio
                        let valueWidth = maxWidth * 0.2 // 1¢ vs 5¢ scale

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(PennyTheme.accentCopper.opacity(0.65))
                                .frame(width: costWidth)

                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(Color.white.opacity(0.95))
                                .frame(width: valueWidth)
                                .overlay(
                                    Text("Value 1¢")
                                        .font(.caption2.bold())
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 6),
                                    alignment: .leading
                                )
                        }
                    }
                }

            HStack(spacing: 8) {
                StatPill(
                    label: "Pennies minted",
                    value: formattedBillions(stat.unitsProduced),
                    icon: "circle.grid.2x1"
                )
                StatPill(
                    label: "Est. net loss",
                    value: "≈\(formattedMillions(stat.annualLossMillions))M",
                    icon: "arrow.down.circle"
                )
            }

            Text("Because the Mint spends more than a cent to make a 1¢ coin, the gap between cost and value shows up as a net loss in its accounts.")
                .font(.footnote)
                .foregroundColor(PennyTheme.secondaryText(scheme))
        }
    }

    private var miniTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Trend in penny production cost")
                .font(.caption.bold())
                .foregroundColor(PennyTheme.secondaryText(scheme))

            GeometryReader { geo in
                let sorted = statsStore.stats.sorted { $0.year < $1.year }
                let maxCost = sorted.map { $0.unitCostCents }.max() ?? 0
                let barSpacing: CGFloat = 8
                let barWidth = max((geo.size.width - CGFloat(sorted.count - 1) * barSpacing) / CGFloat(max(sorted.count, 1)), 16)

                HStack(alignment: .bottom, spacing: barSpacing) {
                    ForEach(sorted) { stat in
                        let ratio = maxCost > 0 ? stat.unitCostCents / maxCost : 0
                        VStack {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(PennyTheme.accentCopper.opacity(
                                    statsStore.currentStat?.year == stat.year ? 0.9 : 0.4
                                ))
                                .frame(width: barWidth,
                                       height: max(10, geo.size.height * ratio))

                            Text("'\(String(stat.year % 100))")
                                .font(.caption2)
                                .foregroundColor(PennyTheme.secondaryText(scheme))
                        }
                    }
                }
            }
            .frame(height: 80)
        }
    }

    // MARK: - Rounding and fairness

    private var roundingFairnessCard: some View {
        PennyCard(title: "Rounding and fairness") {
            VStack(alignment: .leading, spacing: 8) {
                Text("If cash totals no longer include pennies, stores need a rounding rule, usually to the nearest 5¢.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                BulletPoint(text: "Symmetric rules (1–2¢ down, 3–4¢ up) keep the average change very small across many purchases.")
                BulletPoint(text: "Rounding barely matters for people who mostly pay with cards, because card amounts aren’t rounded.")
                BulletPoint(text: "Rounding matters more for people who rely on cash and make lots of small purchases.")

                Text("Economists often focus on distribution: even if the average effect is tiny, it matters who pays those extra cents.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .padding(.top, 6)
            }
        }
    }

    // MARK: - Reasons to keep the penny

    private var reasonsToKeepCard: some View {
        PennyCard(title: "Why some people want to keep the penny") {
            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "Protects cash users who prefer exact totals with no rounding at all.")
                BulletPoint(text: "Keeps fine-grained pricing (like $9.99) and small price changes available.")
                BulletPoint(text: "Carries sentimental and cultural value through charity jars, collections, and “lucky penny” traditions.")
                BulletPoint(text: "Supports industries that supply the metals used in the coin.")

                Text("From this point of view, the penny is less about efficiency and more about habits, symbols, and small protections for certain groups of people.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .padding(.top, 6)
            }
        }
    }

    // MARK: - Who wins, who loses?

    private var whoWinsCard: some View {
        PennyCard(title: "Who gains and who gives something up?") {
            VStack(alignment: .leading, spacing: 8) {
                Text("If the penny disappeared and fair rounding rules were used:")
                    .font(.footnote.bold())
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                BulletPoint(text: "The Mint and federal government likely save money by not producing a coin that costs more than it is worth.")
                BulletPoint(text: "Most card-heavy shoppers notice almost no change in what they pay.")
                BulletPoint(text: "Cash-heavy shoppers could see a small shift up or down in their yearly spending, depending on how stores round.")

                Text("Reasonable people can disagree. Some focus on cutting costs and saving time at the register. Others focus on exact prices, symbolism, and tiny amounts of protection for everyday cash users.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .padding(.top, 6)
            }
        }
    }

    // MARK: - Poll

    private var pollCard: some View {
        PennyCard(title: "Your view") {
            VStack(alignment: .leading, spacing: 12) {
                if let last = pollStore.lastChoice {
                    Text("You chose **\(last.label)**. The chart below shows how opinions on this device are currently split.")
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                } else {
                    Text("After looking at the numbers and arguments, which option feels closest to your view right now?")
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                }

                HStack(spacing: 10) {
                    ForEach(PennyOpinionChoice.allCases) { choice in
                        Button {
                            pollStore.vote(choice)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: choice.icon)
                                    .font(.subheadline)
                                Text(choiceShortLabel(for: choice))
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(tintColor(for: choice))
                    }
                }

                if pollStore.totalVotes > 0 {
                    pollResultsChart
                } else {
                    Text("No votes have been recorded on this device yet.")
                        .font(.footnote.italic())
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                        .padding(.top, 4)
                }
            }
        }
    }

    private var pollResultsChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Local results on this device")
                .font(.caption.bold())
                .foregroundColor(PennyTheme.secondaryText(scheme))

            GeometryReader { geo in
                let total = Double(max(pollStore.totalVotes, 1))
                let maxWidth = geo.size.width

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(PennyOpinionChoice.allCases) { choice in
                        let votes = pollStore.votes(for: choice)
                        let fraction = Double(votes) / total
                        let width = max(maxWidth * fraction, 4)

                        HStack {
                            Text(choice.label)
                                .font(.caption)
                                .foregroundColor(PennyTheme.secondaryText(scheme))
                                .frame(width: 140, alignment: .leading)

                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(tintColor(for: choice).opacity(0.85))
                                .frame(width: width, height: 10)

                            Text("\(votes) • \(Int(pollStore.percentage(for: choice)))%")
                                .font(.caption2.monospacedDigit())
                                .foregroundColor(PennyTheme.secondaryText(scheme))
                        }
                    }
                }
            }
            .frame(height: 70)
        }
    }

    // MARK: - Helpers

    private func formattedMillions(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func formattedBillions(_ units: Double) -> String {
        let billions = units / 1_000_000_000.0
        return String(format: "%.1fB", billions)
    }

    private func tintColor(for choice: PennyOpinionChoice) -> Color {
        switch choice {
        case .keep:
            return PennyTheme.accentMint
        case .retire:
            return PennyTheme.accentCopper
        case .unsure:
            return Color.gray
        }
    }

    private func choiceShortLabel(for choice: PennyOpinionChoice) -> String {
        switch choice {
        case .keep:   return "Keep"
        case .retire: return "Retire"
        case .unsure: return "Unsure"
        }
    }
}
