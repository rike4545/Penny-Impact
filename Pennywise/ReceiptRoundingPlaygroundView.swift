//
//  ReceiptRoundingPlaygroundView.swift
//  Pennywise
//
//  Interactive “build a receipt” playground:
//  • Multiple items
//  • Choose rounding rule
//  • Cash vs card
//

import SwiftUI

@MainActor
struct ReceiptRoundingPlaygroundView: View {
    @Environment(\.colorScheme) private var scheme

    @State private var items: [ReceiptItem] = [
        .init(name: "Coffee", priceText: "3.75"),
        .init(name: "Bagel", priceText: "2.60"),
        .init(name: "Muffin", priceText: "2.15")
    ]

    @State private var selectedRule: RoundingRule = .nearestFive
    @State private var isCashPurchase: Bool = true

    // MARK: - Derived values

    private var subtotal: Double {
        items.compactMap { Double($0.priceText.replacingOccurrences(of: ",", with: ".")) }
            .filter { $0 >= 0 }
            .reduce(0, +)
    }

    private var roundedTotal: Double {
        guard isCashPurchase else { return subtotal }
        return roundedTotal(for: subtotal, rule: selectedRule)
    }

    private var deltaAmount: Double {
        (roundedTotal - subtotal).rounded(toPlaces: 2)
    }

    private var deltaSummaryText: String {
        let delta = deltaAmount
        if delta > 0 {
            return "You’d pay more because of rounding."
        } else if delta < 0 {
            return "You’d pay a bit less because of rounding."
        } else {
            return "Rounding doesn’t change this bill."
        }
    }

    private var deltaEmoji: String {
        let delta = deltaAmount
        if delta > 0 {
            return "⬆️"
        } else if delta < 0 {
            return "⬇️"
        } else {
            return "⚖️"
        }
    }

    // MARK: - Body

    var body: some View {
        PennyScreenBackground(
            title: "Receipt playground",
            subtitle: "Build a bill and see how rounding changes what you pay."
        ) {
            VStack(spacing: 16) {
                receiptBuilderCard
                ruleCard
                resultCard
            }
        }
        .toolbarTitleDisplayMode(.inline)
    }

    // MARK: - Cards

    private var receiptBuilderCard: some View {
        PennyCard(title: "Your receipt") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach($items) { $item in
                    HStack(spacing: 12) {
                        TextField("Item", text: $item.name)
                            .textFieldStyle(.roundedBorder)

                        TextField("Price", text: $item.priceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)

                        Button {
                            remove(item)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove item")
                    }
                }

                Button {
                    addItem()
                } label: {
                    Label("Add item", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(PennyTheme.accentCopper)

                Divider().padding(.vertical, 4)

                HStack {
                    Text("Subtotal (no rounding)")
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                    Spacer()
                    Text(formattedCurrency(subtotal))
                        .font(.headline.monospacedDigit())
                }

                if items.isEmpty {
                    Text("Add at least one item to see the effect of rounding.")
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                        .padding(.top, 4)
                }

                HStack {
                    Button {
                        randomizeReceipt()
                    } label: {
                        Label("Random grocery trip", systemImage: "dice")
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }
            }
        }
    }

    private var ruleCard: some View {
        PennyCard(title: "How are we paying?") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Rounding rule", selection: $selectedRule) {
                    ForEach(RoundingRule.allCases) { rule in
                        Text(rule.rawValue).tag(rule)
                    }
                }
                .pickerStyle(.segmented)

                Toggle(isOn: $isCashPurchase.animation()) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isCashPurchase ? "Cash purchase" : "Card / digital")
                            .font(.subheadline.bold())
                        Text(isCashPurchase
                             ? "Rounding only applies because we’re paying with physical cash."
                             : "No rounding here – card and digital payments use the exact total."
                        )
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                    }
                }
            }
        }
    }

    private var resultCard: some View {
        PennyCard(title: "Results") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Exact total")
                    Spacer()
                    Text(formattedCurrency(subtotal))
                        .font(.headline.monospacedDigit())
                }

                if isCashPurchase {
                    HStack {
                        Text("Rounded cash total")
                        Spacer()
                        Text(formattedCurrency(roundedTotal))
                            .font(.headline.monospacedDigit())
                    }

                    StatPill(
                        label: "Difference",
                        value: "\(formattedCurrency(deltaAmount)) \(deltaEmoji)",
                        icon: "arrow.up.arrow.down"
                    )

                    BulletPoint(text: deltaSummaryText)
                    BulletPoint(text: "Try changing one price and watch how the rounded total jumps in 5¢ steps.")
                    BulletPoint(text: "Tap “Random grocery trip” to see different real-world examples.")
                } else {
                    BulletPoint(text: "Because we’re paying with card or digital, there’s no rounding and no change to the total.")
                }
            }
        }
    }

    // MARK: - Actions

    private func addItem() {
        items.append(.init(name: "Item \(items.count + 1)", priceText: "1.00"))
    }

    private func remove(_ item: ReceiptItem) {
        items.removeAll { $0.id == item.id }
    }

    private func randomizeReceipt() {
        let examples: [[ReceiptItem]] = [
            [
                .init(name: "Milk", priceText: "3.49"),
                .init(name: "Cereal", priceText: "4.29"),
                .init(name: "Bananas", priceText: "1.83"),
                .init(name: "Yogurt", priceText: "2.10")
            ],
            [
                .init(name: "Burger", priceText: "9.95"),
                .init(name: "Fries", priceText: "3.25"),
                .init(name: "Soda", priceText: "2.10")
            ],
            [
                .init(name: "Notebook", priceText: "2.79"),
                .init(name: "Pens", priceText: "1.99"),
                .init(name: "Highlighter", priceText: "1.49"),
                .init(name: "Folder", priceText: "0.99")
            ]
        ]

        if let random = examples.randomElement() {
            items = random
        }
    }

    // MARK: - Helpers

    private func roundedTotal(for amount: Double, rule: RoundingRule) -> Double {
        guard amount >= 0 else { return amount }

        let cents = (amount * 100).rounded()
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

    private func formattedCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

// MARK: - Models + helpers

private struct ReceiptItem: Identifiable {
    let id = UUID()
    var name: String
    var priceText: String
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        guard places >= 0 else { return self }
        let factor = pow(10.0, Double(places))
        return (self * factor).rounded() / factor
    }
}
