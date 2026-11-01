//
//  RoundingLogEntry.swift
//  Pennywise
//
//  Persistent “rounding journal”:
//  • Log real-world purchases
//  • See saved vs overpaid
//  • Net impact over time
//

import SwiftUI
import Combine

// MARK: - Model

struct RoundingLogEntry: Identifiable, Codable, Hashable {
    enum PaymentMethod: String, CaseIterable, Identifiable, Codable {
        case cash = "Cash"
        case card = "Card / digital"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .cash: return "Cash"
            case .card: return "Card / digital"
            }
        }

        var systemImageName: String {
            switch self {
            case .cash: return "banknote"
            case .card: return "creditcard"
            }
        }
    }

    enum Direction: String, Codable {
        case saved
        case paidMore
        case neutral
    }

    let id: UUID
    var date: Date
    var storeName: String
    var rule: RoundingRule
    var paymentMethod: PaymentMethod
    var exactTotal: Double
    var roundedTotal: Double
    var note: String?

    /// RoundedTotal - ExactTotal (positive = paid more, negative = saved).
    var difference: Double {
        (roundedTotal - exactTotal).roundedToCents()
    }

    var direction: Direction {
        guard paymentMethod == .cash else { return .neutral }
        if difference > 0 { return .paidMore }
        if difference < 0 { return .saved }
        return .neutral
    }
}

// MARK: - Store

@MainActor
final class RoundingLogStore: ObservableObject {
    @Published private(set) var entries: [RoundingLogEntry] = []

    private let storageKey = "RoundingLogEntries"

    init() {
        load()
    }

    // CRUD

    func add(
        date: Date = Date(),
        storeName: String,
        rule: RoundingRule,
        paymentMethod: RoundingLogEntry.PaymentMethod,
        exactTotal: Double,
        roundedTotal: Double,
        note: String?
    ) {
        let trimmedName = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = RoundingLogEntry(
            id: UUID(),
            date: date,
            storeName: trimmedName.isEmpty ? "Untitled purchase" : trimmedName,
            rule: rule,
            paymentMethod: paymentMethod,
            exactTotal: exactTotal,
            roundedTotal: roundedTotal,
            note: note?.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        entries.insert(entry, at: 0)
        save()
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    func removeAll() {
        entries.removeAll()
        save()
    }

    // Aggregates

    var totalSaved: Double {
        entries
            .filter { $0.direction == .saved }
            .map { -$0.difference } // difference is negative when saved
            .reduce(0, +)
            .roundedToCents()
    }

    var totalPaidMore: Double {
        entries
            .filter { $0.direction == .paidMore }
            .map { $0.difference } // positive when paid more
            .reduce(0, +)
            .roundedToCents()
    }

    /// Sum of all differences (positive = net overpay, negative = net savings).
    var netImpact: Double {
        entries.map { $0.difference }.reduce(0, +).roundedToCents()
    }

    // Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            entries = []
            return
        }

        do {
            entries = try JSONDecoder().decode([RoundingLogEntry].self, from: data)
        } catch {
            print("Failed to decode rounding log entries: \(error)")
            entries = []
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to encode rounding log entries: \(error)")
        }
    }
}

// MARK: - Main Journal View

@MainActor
struct RoundingJournalView: View {
    @Environment(\.colorScheme) private var scheme

    @StateObject private var store = RoundingLogStore()

    @State private var showingAddSheet = false
    @State private var showingResetConfirmation = false

    private var hasEntries: Bool {
        !store.entries.isEmpty
    }

    private var netSummaryText: String {
        let net = store.netImpact
        if net > 0 {
            return "Overall you’ve paid \(formattedCurrency(net)) more because of rounding."
        } else if net < 0 {
            return "Overall you’ve saved \(formattedCurrency(-net)) thanks to rounding."
        } else {
            return "So far, rounding has perfectly balanced out — you’re even."
        }
    }

    var body: some View {
        PennyScreenBackground(
            title: "My rounding journal",
            subtitle: "Log real cash purchases and see whether rounding usually helps or hurts you."
        ) {
            VStack(spacing: 16) {
                summaryCard
                logListCard
                SponsoredCard(.journal)
            }
        }
        .loadsSponsoredCard(.journal)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }

                if hasEntries {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRoundingLogEntryView(store: store)
        }
        .alert("Clear all entries?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear all", role: .destructive) {
                store.removeAll()
            }
        } message: {
            Text("This will permanently remove every entry in your rounding journal on this device.")
        }
    }

    // MARK: - Cards

    private var summaryCard: some View {
        PennyCard(title: "At a glance") {
            VStack(alignment: .leading, spacing: 12) {
                if !hasEntries {
                    Text("No entries yet.")
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                    BulletPoint(text: "Tap the + button to log your next cash purchase and see how rounding affects you over time.")
                } else {
                    HStack {
                        StatPill(
                            label: "You’ve saved",
                            value: formattedCurrency(store.totalSaved),
                            icon: "arrow.down.circle"
                        )
                        StatPill(
                            label: "You’ve overpaid",
                            value: formattedCurrency(store.totalPaidMore),
                            icon: "arrow.up.circle"
                        )
                    }

                    Text(netSummaryText)
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))

                    BulletPoint(text: "Log a week or a month of purchases to see whether rounding trends in your favor.")
                }
            }
        }
    }

    private var logListCard: some View {
        PennyCard(title: "Your entries") {
            if !hasEntries {
                Text("Once you log a purchase, it will appear here.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
            } else {
                // Use a bounded height list so it still looks like a card.
                List {
                    ForEach(store.entries) { entry in
                        RoundingLogRow(entry: entry)
                    }
                    .onDelete(perform: store.delete)
                }
                .listStyle(.plain)
                .frame(maxHeight: 340)
            }
        }
    }

    // MARK: - Helpers

    private func formattedCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

// MARK: - Row View

private struct RoundingLogRow: View {
    @Environment(\.colorScheme) private var scheme
    let entry: RoundingLogEntry

    private var differenceText: String {
        switch entry.direction {
        case .saved:
            return "Saved \(formattedCurrency(-entry.difference))"
        case .paidMore:
            return "Paid \(formattedCurrency(entry.difference)) more"
        case .neutral:
            return "No change from rounding"
        }
    }

    private var differenceColor: Color {
        switch entry.direction {
        case .saved: return .green
        case .paidMore: return .red
        case .neutral: return PennyTheme.secondaryText(scheme)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.storeName)
                    .font(.subheadline.bold())
                Spacer()
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
            }

            HStack(spacing: 8) {
                Text("\(formattedCurrency(entry.exactTotal)) → \(formattedCurrency(entry.roundedTotal))")
                    .font(.footnote.monospacedDigit())

                Text(differenceText)
                    .font(.caption)
                    .foregroundColor(differenceColor)
            }

            HStack(spacing: 8) {
                labelCapsule(text: entry.rule.rawValue, systemImage: "arrow.up.arrow.down.circle")
                labelCapsule(text: entry.paymentMethod.label, systemImage: entry.paymentMethod.systemImageName)
            }

            if let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.caption)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }

    private func labelCapsule(text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
            Text(text)
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.15))
        )
    }

    private func formattedCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

// MARK: - Add Entry Sheet

@MainActor
struct AddRoundingLogEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @ObservedObject var store: RoundingLogStore

    @State private var date = Date()
    @State private var storeName: String = ""
    @State private var paymentMethod: RoundingLogEntry.PaymentMethod = .cash
    @State private var rule: RoundingRule = .nearestFive
    @State private var exactTotalText: String = ""
    @State private var note: String = ""

    private var exactTotal: Double {
        Double(exactTotalText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var roundedTotal: Double {
        if paymentMethod == .cash {
            return rule.roundedTotal(for: exactTotal)
        } else {
            return exactTotal
        }
    }

    private var difference: Double {
        (roundedTotal - exactTotal).roundedToCents()
    }

    private var differenceSummary: String {
        guard paymentMethod == .cash else {
            return "No change from rounding on this purchase."
        }

        if difference > 0 {
            return "You pay \(formattedCurrency(difference)) more because of rounding."
        } else if difference < 0 {
            return "You save \(formattedCurrency(-difference)) thanks to rounding."
        } else {
            return "Rounding doesn’t change this total."
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Purchase details") {
                    TextField("Store / place", text: $storeName)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Exact total (before rounding)", text: $exactTotalText)
                        .keyboardType(.decimalPad)
                }

                Section("How was it paid?") {
                    Picker("Payment method", selection: $paymentMethod) {
                        ForEach(RoundingLogEntry.PaymentMethod.allCases) { method in
                            Text(method.label).tag(method)
                        }
                    }

                    if paymentMethod == .cash {
                        Picker("Rounding rule used", selection: $rule) {
                            ForEach(RoundingRule.allCases) { r in
                                Text(r.rawValue).tag(r)
                            }
                        }
                    }
                }

                if exactTotal > 0 {
                    Section("Result") {
                        HStack {
                            Text("Rounded total")
                            Spacer()
                            Text(formattedCurrency(roundedTotal))
                                .font(.body.monospacedDigit())
                        }

                        Text(differenceSummary)
                            .font(.footnote)
                            .foregroundColor(PennyTheme.secondaryText(scheme))
                    }
                }

                Section("Notes") {
                    TextField("Anything special about this purchase?", text: $note)
                }
            }
            .navigationTitle("Log purchase")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.add(
                            date: date,
                            storeName: storeName,
                            rule: rule,
                            paymentMethod: paymentMethod,
                            exactTotal: exactTotal,
                            roundedTotal: roundedTotal,
                            note: note
                        )
                        dismiss()
                    }
                    .disabled(exactTotal <= 0)
                }
            }
        }
    }

    private func formattedCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

// MARK: - Double helper

private extension Double {
    func roundedToCents() -> Double {
        let factor = 100.0
        return (self * factor).rounded() / factor
    }
}
