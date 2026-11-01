//
//  RoundingInsightsView.swift
//  Pennywise
//
//  “AI-style” rounding coach:
//
//  • Reads your RoundingLogStore
//  • Switch perspectives: Customer / Store / Teacher
//  • Answer-style modes: Overall / Fairness / Habits / Rules
//  • Confidence meter based on how much data you’ve logged
//  • What-if slider: “What if I used less cash?”
//

import SwiftUI

@MainActor
struct RoundingInsightsView: View {
    @Environment(\.colorScheme) private var scheme

    /// Inject the same store used by RoundingJournalView
    @ObservedObject var store: RoundingLogStore

    @State private var perspective: CoachPerspective = .customer
    @State private var question: InsightQuestion = .overall
    @State private var whatIfCashFactor: Double = 1.0 // 1.0 = current habits, 0.0 = no cash

    // MARK: - Data slices

    private var entries: [RoundingLogEntry] {
        store.entries
    }

    private var totalEntries: Int { entries.count }

    private var cashEntries: [RoundingLogEntry] {
        entries.filter { $0.paymentMethod == .cash }
    }

    private var totalCashEntries: Int { cashEntries.count }

    private var savedEntries: [RoundingLogEntry] {
        cashEntries.filter { $0.direction == .saved }
    }

    private var paidMoreEntries: [RoundingLogEntry] {
        cashEntries.filter { $0.direction == .paidMore }
    }

    private var neutralEntries: [RoundingLogEntry] {
        cashEntries.filter { $0.direction == .neutral }
    }

    private var savedCount: Int { savedEntries.count }
    private var paidMoreCount: Int { paidMoreEntries.count }
    private var neutralCount: Int { neutralEntries.count }

    // Rule usage
    private var ruleUsageCounts: [RoundingRule: Int] {
        Dictionary(
            grouping: cashEntries,
            by: { $0.rule }
        ).mapValues { $0.count }
    }

    private var mostUsedRule: RoundingRule? {
        ruleUsageCounts.max(by: { $0.value < $1.value })?.key
    }

    private var usesMultipleRules: Bool {
        ruleUsageCounts.keys.count > 1
    }

    // Aggregate impacts

    /// Net impact observed so far (positive = overpaid, negative = net saved).
    private var netImpact: Double {
        store.netImpact
    }

    private var netImpactEmoji: String {
        if netImpact > 0 {
            return "⬆️"
        } else if netImpact < 0 {
            return "⬇️"
        } else {
            return "⚖️"
        }
    }

    /// Average difference per *cash* purchase (can be small but insightful).
    private var averageDifferencePerCash: Double {
        guard totalCashEntries > 0 else { return 0 }
        let sum = cashEntries.map { $0.difference }.reduce(0, +)
        return (sum / Double(totalCashEntries)).roundedToCents()
    }

    /// Average absolute difference per cash purchase (how “swingy” rounding is).
    private var averageAbsoluteDifferencePerCash: Double {
        guard totalCashEntries > 0 else { return 0 }
        let sum = cashEntries.map { abs($0.difference) }.reduce(0, +)
        return (sum / Double(totalCashEntries)).roundedToCents()
    }

    // Confidence model

    /// 0–1 confidence based on how much data we have.
    private var confidenceLevel: Double {
        guard totalCashEntries > 0 else { return 0 }
        // Saturate confidence around ~30 cash entries.
        let capped = min(Double(totalCashEntries), 30.0)
        return capped / 30.0
    }

    private var confidenceLabel: String {
        if totalEntries == 0 {
            return "No data yet"
        } else if confidenceLevel < 0.25 {
            return "Very low confidence"
        } else if confidenceLevel < 0.5 {
            return "Low confidence"
        } else if confidenceLevel < 0.8 {
            return "Moderate confidence"
        } else {
            return "High confidence"
        }
    }

    private var confidenceDetail: String {
        if totalEntries == 0 {
            return "Log a few real purchases and I’ll start forming an opinion."
        } else if totalCashEntries == 0 {
            return "You rarely use cash, so rounding doesn’t show up much in your data."
        } else if confidenceLevel < 0.25 {
            return "This is mostly based on a small handful of cash purchases — treat it as a hint, not a verdict."
        } else if confidenceLevel < 0.5 {
            return "You’ve logged several cash purchases; the pattern is starting to emerge."
        } else if confidenceLevel < 0.8 {
            return "You’ve logged quite a few cash purchases; this summary is fairly representative."
        } else {
            return "You’ve logged a lot of cash purchases; these patterns are likely close to your real habits."
        }
    }

    // What-if model

    /// “What if I used this fraction of my current cash usage?”
    private var whatIfNetImpact: Double {
        // Simple linear scaling: if you used half as much cash, half the net impact.
        (netImpact * whatIfCashFactor).roundedToCents()
    }

    // MARK: - Coach text

    private var coachTitle: String {
        switch perspective {
        case .customer:
            return "From your point of view…"
        case .store:
            return "From a store’s point of view…"
        case .teacher:
            return "From a teacher’s point of view…"
        }
    }

    private var coachHeadline: String {
        if totalEntries == 0 {
            return "I don’t have any data yet."
        }

        switch (perspective, question) {
        case (.customer, .overall):
            if netImpact > 0 {
                return "Rounding is nudging your costs slightly upward overall."
            } else if netImpact < 0 {
                return "So far, rounding has been a tiny discount for you."
            } else {
                return "Rounding has balanced out for you so far."
            }

        case (.customer, .fairness):
            if totalCashEntries == 0 {
                return "You almost never use cash, so rounding is mostly a non-issue for you."
            } else if savedCount == paidMoreCount {
                return "Your saved vs overpaid cash purchases are basically even."
            } else if savedCount > paidMoreCount {
                return "More of your cash purchases round in your favor than against you."
            } else {
                return "More of your cash purchases round up instead of down."
            }

        case (.customer, .habits):
            if totalCashEntries == 0 {
                return "Your habit is clear: you’re a digital payer. Rounding rarely touches you."
            } else if averageAbsoluteDifferencePerCash < 0.02 {
                return "Most of your cash purchases have very tiny rounding swings — usually just a cent or two."
            } else {
                return "When rounding hits your cash purchases, it tends to move totals by a few cents at a time."
            }

        case (.customer, .rules):
            if mostUsedRule == nil {
                return "I haven’t seen any rounding rules in your data yet."
            } else {
                return "Your purchases mostly use the “\(mostUsedRule!.rawValue)” rule."
            }

        case (.store, .overall):
            if totalCashEntries == 0 {
                return "With your current habits, a store wouldn’t see much rounding revenue at all."
            } else if netImpact > 0 {
                return "If an entire store full of customers behaved like you, rounding would add a small amount of extra revenue."
            } else if netImpact < 0 {
                return "If everyone behaved like you, a store would actually lose a little revenue to rounding."
            } else {
                return "Your pattern looks rounding-neutral from a store’s perspective."
            }

        case (.store, .fairness):
            if usesMultipleRules {
                return "You’ve seen different rounding rules being used — great material for a fairness discussion."
            } else if let rule = mostUsedRule {
                return "Your data mostly reflects a single policy: “\(rule.rawValue)”."
            } else {
                return "I don’t yet see enough variety in rules to comment on fairness."
            }

        case (.store, .habits):
            if totalCashEntries == 0 {
                return "From a store’s point of view, you’re a low-rounding-risk customer — almost always digital."
            } else if paidMoreCount > savedCount {
                return "Your pattern skews toward totals that round up — a store would prefer customers like you."
            } else if savedCount > paidMoreCount {
                return "Your purchases skew toward totals that round down — generous for you, less so for the store."
            } else {
                return "Your purchases show a balanced mix of ups and downs."
            }

        case (.store, .rules):
            if usesMultipleRules {
                return "You’ve encountered multiple policies in the wild, which stores might choose based on marketing or margin."
            } else {
                return "Your data mostly shows one policy; the store may be prioritizing simplicity over experimentation."
            }

        case (.teacher, .overall):
            return "You’ve built a small, real-world dataset that’s perfect for a lesson on rounding, fairness, and policy."

        case (.teacher, .fairness):
            if usesMultipleRules {
                return "Your logs include different rounding rules — ideal for a “which policy is fair?” class debate."
            } else if mostUsedRule != nil {
                return "Most of your data uses one rule; you can ask students how the story would change if a different rule were used."
            } else {
                return "Log a few more purchases with different rules to explore fairness in depth."
            }

        case (.teacher, .habits):
            if totalCashEntries == 0 {
                return "Your own data shows a modern habit: almost everything is digital — a good entry point for discussing cash vs card."
            } else {
                return "Your logs can show students how small rounding changes stack up when someone uses cash regularly."
            }

        case (.teacher, .rules):
            if usesMultipleRules {
                return "You’ve seen multiple rounding policies; students can compare who benefits under each one."
            } else {
                return "Introduce hypothetical alternate policies and have students recompute your real logs under each rule."
            }
        }
    }

    private var coachBullets: [String] {
        guard totalEntries > 0 else {
            return [
                "Log a few cash purchases in the journal and I’ll tell you whether rounding usually helps or hurts you.",
                "If you travel or see different rounding policies, note the rule in each entry — I use that to compare fairness."
            ]
        }

        var lines: [String] = []

        switch (perspective, question) {
        case (.customer, .overall):
            lines.append("Net impact so far: \(formattedCurrency(abs(netImpact))) \(netImpact > 0 ? "overpaid" : (netImpact < 0 ? "saved" : "from rounding overall."))")
            if totalCashEntries > 0 {
                lines.append("Average difference per cash purchase: \(formattedCurrency(averageDifferencePerCash)) \(netImpact > 0 ? "in extra cost on average." : (netImpact < 0 ? "in savings on average." : "with ups and downs cancelling out."))")
            }

        case (.customer, .fairness):
            lines.append("Cash entries so far: \(totalCashEntries). Saved on \(savedCount), overpaid on \(paidMoreCount), neutral on \(neutralCount).")
            if averageAbsoluteDifferencePerCash > 0 {
                lines.append("Typical size of a rounding step in your data: about \(formattedCurrency(averageAbsoluteDifferencePerCash)) per cash purchase.")
            }

        case (.customer, .habits):
            lines.append("Total purchases logged: \(totalEntries). Cash: \(totalCashEntries), digital: \(totalEntries - totalCashEntries).")
            if totalCashEntries > 0 {
                let cashShare = Double(totalCashEntries) / Double(totalEntries)
                lines.append("Roughly \(Int(cashShare * 100))% of your purchases in this journal involve cash.")
            }

        case (.customer, .rules):
            if let rule = mostUsedRule {
                lines.append("Most of your cash purchases use “\(rule.rawValue)”.")
            }
            if usesMultipleRules {
                lines.append("You’ve seen multiple rounding rules; that’s why your experiences can feel inconsistent across stores.")
            }

        case (.store, .overall):
            if totalCashEntries > 0 {
                lines.append("If your pattern of cash purchases were typical, rounding would change store revenue by about \(formattedCurrency(netImpact)) over the span of your journal.")
            }
            if averageAbsoluteDifferencePerCash > 0 {
                lines.append("Each cash transaction typically shifts the store’s revenue by about \(formattedCurrency(averageAbsoluteDifferencePerCash)) up or down.")
            }

        case (.store, .fairness):
            if usesMultipleRules {
                lines.append("Your data can illustrate how different rounding policies move money between customer and store.")
            }
            if let rule = mostUsedRule {
                lines.append("You primarily experience “\(rule.rawValue)”, which you can contrast with “Always up” or “Always down” scenarios.")
            }

        case (.store, .habits):
            if totalCashEntries > 0 {
                let cashShare = Double(totalCashEntries) / Double(totalEntries)
                lines.append("From a store’s view, around \(Int(cashShare * 100))% of your transactions are “rounding-exposed” cash transactions.")
            }
            if paidMoreCount > savedCount {
                lines.append("In your logs, the store comes out ahead on more cash purchases than it loses on.")
            }

        case (.store, .rules):
            lines.append("You can use your own entries to test “What if every store used a different rule?” and recompute totals with students.")

        case (.teacher, .overall):
            lines.append("You have \(totalEntries) real entries, which is enough for a small class exercise or project.")
            if totalCashEntries > 0 {
                lines.append("Cash vs digital split: \(totalCashEntries) cash, \(totalEntries - totalCashEntries) digital.")
            }

        case (.teacher, .fairness):
            if usesMultipleRules {
                lines.append("Your logs already include different policies — perfect for asking who wins and who loses under each.")
            } else {
                lines.append("You can introduce alternate rules and have students re-run your data under each policy.")
            }

        case (.teacher, .habits):
            lines.append("Students can compare your “adult” pattern to their own hypothetical or observed spending habits.")
            if totalCashEntries == 0 {
                lines.append("Your digital-heavy pattern can start a conversation about cashless payments and who might be left out.")
            }

        case (.teacher, .rules):
            if let rule = mostUsedRule {
                lines.append("Your data mostly reflects “\(rule.rawValue)”, but students can imagine how results change under other rules.")
            }
        }

        // Always add a gentle suggestion line
        lines.append("You can always add more entries over time — I’ll quietly update my picture of your rounding world.")
        return lines
    }

    // MARK: - Body

    var body: some View {
        PennyScreenBackground(
            title: "Rounding coach",
            subtitle: "An AI-style summary built from your own rounding journal."
        ) {
            VStack(spacing: 16) {
                modeSelectorCard
                confidenceCard
                insightsCard
                whatIfCard
            }
        }
        .toolbarTitleDisplayMode(.inline)
    }

    // MARK: - Cards

    private var modeSelectorCard: some View {
        PennyCard(title: "How should I think about your data?") {
            VStack(alignment: .leading, spacing: 12) {
                // Perspective
                Picker("Perspective", selection: $perspective) {
                    ForEach(CoachPerspective.allCases) { mode in
                        Label(mode.label, systemImage: mode.systemImageName)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                // Question type
                Picker("Question", selection: $question) {
                    ForEach(InsightQuestion.allCases) { q in
                        Text(q.label).tag(q)
                    }
                }
                .pickerStyle(.segmented)

                Text(perspective.description(for: question))
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var confidenceCard: some View {
        PennyCard(title: "How sure am I?") {
            VStack(alignment: .leading, spacing: 8) {
                if totalEntries == 0 {
                    Text("No data yet")
                        .font(.subheadline.bold())
                    Text("Once you start logging purchases, I’ll show you how confident I am in these patterns.")
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                } else {
                    HStack {
                        StatPill(
                            label: "Confidence",
                            value: confidenceLabel,
                            icon: "brain.head.profile"
                        )

                        StatPill(
                            label: "Entries",
                            value: "\(totalEntries)",
                            icon: "list.bullet"
                        )
                    }

                    // Simple confidence bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.secondary.opacity(0.2))
                            RoundedRectangle(cornerRadius: 8)
                                .fill(PennyTheme.accentCopper.opacity(0.85))
                                .frame(width: geo.size.width * confidenceLevel)
                        }
                    }
                    .frame(height: 10)

                    Text(confidenceDetail)
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                }
            }
        }
    }

    private var insightsCard: some View {
        PennyCard(title: coachTitle) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(coachHeadline) \(totalEntries == 0 ? "" : netImpactEmoji)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(PennyTheme.primaryText(scheme))

                ForEach(Array(coachBullets.enumerated()), id: \.offset) { _, line in
                    BulletPoint(text: line, icon: "sparkles")
                }
            }
        }
    }

    private var whatIfCard: some View {
        PennyCard(title: "What if you changed your cash habits?") {
            VStack(alignment: .leading, spacing: 12) {
                if totalEntries == 0 {
                    Text("Once you have a few entries, this section will show how using more or less cash could change your net rounding impact.")
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                } else {
                    Text("Slide from “no cash” to “same as now” to see how your net rounding impact might change.")
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))

                    HStack {
                        Text("No cash")
                            .font(.caption)
                            .foregroundColor(PennyTheme.secondaryText(scheme))
                        Slider(value: $whatIfCashFactor, in: 0...1) {
                            Text("Cash factor")
                        }
                        Text("Now")
                            .font(.caption)
                            .foregroundColor(PennyTheme.secondaryText(scheme))
                    }

                    let current = netImpact
                    let hypothetical = whatIfNetImpact

                    HStack {
                        StatPill(
                            label: "Now",
                            value: formattedCurrency(current),
                            icon: current > 0 ? "arrow.up.circle" : (current < 0 ? "arrow.down.circle" : "equal.circle")
                        )

                        StatPill(
                            label: "What if",
                            value: formattedCurrency(hypothetical),
                            icon: hypothetical > 0 ? "arrow.up.circle" : (hypothetical < 0 ? "arrow.down.circle" : "equal.circle")
                        )
                    }

                    let explanation = whatIfExplanation(current: current, hypothetical: hypothetical)
                    Text(explanation)
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                }
            }
        }
    }

    // MARK: - Helpers

    private func whatIfExplanation(current: Double, hypothetical: Double) -> String {
        if whatIfCashFactor == 1 {
            return "This matches your current pattern — you’re not changing how much you use cash."
        } else if whatIfCashFactor == 0 {
            return "In a fully cash-free scenario, penny rounding disappears for you. Only posted prices matter."
        } else if hypothetical == 0 {
            return "At this level of cash usage, your net effect from rounding would likely be close to zero."
        } else if abs(hypothetical) < abs(current) {
            return "At this level of cash usage, rounding would probably matter less for your budget than it does now."
        } else if abs(hypothetical) > abs(current) {
            return "Using cash this often would make rounding a bit more noticeable in your budget than it is today."
        } else {
            return "This level of cash usage leaves your net rounding impact about the same as it is now."
        }
    }

    private func formattedCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = .current
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

// MARK: - Enums

private enum CoachPerspective: String, CaseIterable, Identifiable {
    case customer
    case store
    case teacher

    var id: String { rawValue }

    var label: String {
        switch self {
        case .customer: return "Customer"
        case .store:    return "Store"
        case .teacher:  return "Teacher"
        }
    }

    var systemImageName: String {
        switch self {
        case .customer: return "person.crop.circle"
        case .store:    return "building.2"
        case .teacher:  return "book.closed"
        }
    }

    func description(for question: InsightQuestion) -> String {
        switch (self, question) {
        case (.customer, .overall):
            return "Big-picture view of what rounding is doing to your budget."
        case (.customer, .fairness):
            return "Is rounding treating you fairly, based on the ups and downs you’ve seen?"
        case (.customer, .habits):
            return "What your logs say about how you actually pay in day-to-day life."
        case (.customer, .rules):
            return "Which rounding rules you’re really living under when you go out and spend."

        case (.store, .overall):
            return "Imagine you’re the store: how do your habits affect revenue?"
        case (.store, .fairness):
            return "How different policies move money between customer and store."
        case (.store, .habits):
            return "What kind of customer you are from a store’s perspective."
        case (.store, .rules):
            return "How a store might think about which rules to use or advertise."

        case (.teacher, .overall):
            return "Use your real data as a mini dataset for a math or civics lesson."
        case (.teacher, .fairness):
            return "Which policy seems “fair” when you look at the actual numbers?"
        case (.teacher, .habits):
            return "Comparing adult spending patterns to those of students."
        case (.teacher, .rules):
            return "How different policies change who wins and who loses."
        }
    }
}

private enum InsightQuestion: String, CaseIterable, Identifiable {
    case overall
    case fairness
    case habits
    case rules

    var id: String { rawValue }

    var label: String {
        switch self {
        case .overall:  return "Overall"
        case .fairness: return "Fair?"
        case .habits:   return "Habits"
        case .rules:    return "Rules"
        }
    }
}

// MARK: - Double helper

private extension Double {
    func roundedToCents() -> Double {
        let factor = 100.0
        return (self * factor).rounded() / factor
    }
}
