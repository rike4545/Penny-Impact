//
//  TeacherWorksheetView.swift
//  Pennywise
//
//  Classroom worksheet generator:
//  • Adjustable grade band + rule mix
//  • Auto-generated exercises + answer key
//  • Short word problems
//

import SwiftUI

@MainActor
struct TeacherWorksheetView: View {
    @Environment(\.colorScheme) private var scheme

    @State private var gradeBand: GradeBand = .upperElementary
    @State private var ruleMode: RuleMode = .mixed
    @State private var includeWordProblems: Bool = true
    @State private var showAnswers: Bool = false

    @State private var problems: [WorksheetProblem] = []
    @State private var wordProblems: [WordProblem] = []

    var body: some View {
        PennyScreenBackground(
            title: "Worksheet generator",
            subtitle: "Print or project quick rounding exercises with an answer key."
        ) {
            settingsCard
            exercisesCard

            if showAnswers {
                answerKeyCard
            }

            teachingIdeasCard
        }
        .toolbarTitleDisplayMode(.inline)
        .onAppear {
            if problems.isEmpty {
                regenerateProblems()
            }
        }
        .onChange(of: gradeBand) { _ in regenerateProblems() }
        .onChange(of: ruleMode) { _ in regenerateProblems() }
        .onChange(of: includeWordProblems) { _ in regenerateProblems() }
    }

    // MARK: - Cards

    private var settingsCard: some View {
        PennyCard(title: "Worksheet settings") {
            VStack(alignment: .leading, spacing: 12) {
                // Grade band
                VStack(alignment: .leading, spacing: 4) {
                    Text("Grade level")
                        .font(.subheadline.weight(.bold))

                    Picker("Grade level", selection: $gradeBand) {
                        ForEach(GradeBand.allCases) { band in
                            Text(band.label).tag(band)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Rule mode
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rounding rules")
                        .font(.subheadline.weight(.bold))

                    Picker("Rounding rules", selection: $ruleMode) {
                        ForEach(RuleMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(ruleMode.explanation)
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Toggle(isOn: $includeWordProblems) {
                    Text("Include short word problems")
                        .font(.subheadline)
                }

                HStack {
                    Button {
                        regenerateProblems()
                        showAnswers = false
                    } label: {
                        Label("New set", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PennyTheme.accentCopper)

                    Spacer()

                    Toggle(isOn: $showAnswers.animation()) {
                        Text("Show answer key")
                            .font(.footnote)
                    }
                    .toggleStyle(.switch)
                }
            }
        }
    }

    private var exercisesCard: some View {
        PennyCard(title: "Exercises") {
            VStack(alignment: .leading, spacing: 8) {
                if problems.isEmpty {
                    Text("Tap **New set** to generate a fresh list of practice problems.")
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                } else {
                    // Numbered computation problems
                    ForEach(problems.indices, id: \.self) { index in
                        let problem = problems[index]

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Problem \(index + 1)")
                                .font(.footnote.weight(.bold))

                            Text(problem.prompt)
                                .font(.footnote.monospacedDigit())

                            // A blank line for students’ work
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.secondary.opacity(0.2))
                                .padding(.top, 6)
                        }
                        .padding(.vertical, 4)

                        if index < problems.count - 1 {
                            Divider()
                        }
                    }
                }

                // Optional word problems
                if includeWordProblems && !wordProblems.isEmpty {
                    Divider().padding(.vertical, 6)

                    Text("Word problems")
                        .font(.subheadline.weight(.bold))
                        .padding(.bottom, 4)

                    ForEach(wordProblems.indices, id: \.self) { index in
                        let wp = wordProblems[index]

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Story \(index + 1)")
                                .font(.footnote.weight(.bold))

                            Text(wp.question)
                                .font(.footnote)
                                .fixedSize(horizontal: false, vertical: true)

                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(Color.secondary.opacity(0.2))
                                .padding(.top, 6)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private var answerKeyCard: some View {
        PennyCard(title: "Answer key") {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(problems.indices, id: \.self) { index in
                    let problem = problems[index]
                    Text("Problem \(index + 1): \(problem.answerLine)")
                        .font(.footnote.monospacedDigit())
                }

                if includeWordProblems && !wordProblems.isEmpty {
                    Divider().padding(.vertical, 4)

                    ForEach(wordProblems.indices, id: \.self) { index in
                        let wp = wordProblems[index]
                        Text("Story \(index + 1): \(wp.answerLine)")
                            .font(.footnote.monospacedDigit())
                    }
                }
            }
        }
    }

    private var teachingIdeasCard: some View {
        PennyCard(title: "Teaching ideas") {
            VStack(alignment: .leading, spacing: 6) {
                BulletPoint(text: "Ask students to predict whether each problem will round up or down before calculating.")
                BulletPoint(text: "Compare sums of “round up” vs “round down” answers to talk about fairness over many purchases.")
                BulletPoint(text: "Have students rewrite one word problem from the customer’s point of view and then from the store’s.")
            }
        }
    }

    // MARK: - Generation

    private func regenerateProblems() {
        problems = generateProblems(for: gradeBand, mode: ruleMode)
        wordProblems = includeWordProblems
            ? generateWordProblems(for: gradeBand, mode: ruleMode)
            : []
    }

    private func generateProblems(for band: GradeBand, mode: RuleMode) -> [WorksheetProblem] {
        let count: Int
        let minTotal: Double
        let maxTotal: Double

        switch band {
        case .upperElementary:
            count = 8
            minTotal = 1.00
            maxTotal = 20.00
        case .middleSchool:
            count = 10
            minTotal = 3.00
            maxTotal = 40.00
        case .highSchool:
            count = 12
            minTotal = 5.00
            maxTotal = 80.00
        }

        var results: [WorksheetProblem] = []

        for _ in 0..<count {
            let total = randomTotal(min: minTotal, max: maxTotal)

            let rule: RoundingRule
            switch mode {
            case .mixed:
                rule = RoundingRule.allCases.randomElement() ?? .nearestFive
            case .nearestFive:
                rule = .nearestFive
            case .alwaysUp:
                rule = .alwaysUp
            case .alwaysDown:
                rule = .alwaysDown
            }

            results.append(WorksheetProblem(baseTotal: total, rule: rule))
        }

        return results
    }

    private func generateWordProblems(for band: GradeBand, mode: RuleMode) -> [WordProblem] {
        let count = band == .upperElementary ? 2 : 3
        var result: [WordProblem] = []

        for _ in 0..<count {
            let base = randomTotal(min: 4.00, max: band == .highSchool ? 60.00 : 30.00)

            let rule: RoundingRule
            switch mode {
            case .mixed:
                rule = RoundingRule.allCases.randomElement() ?? .nearestFive
            case .nearestFive:
                rule = .nearestFive
            case .alwaysUp:
                rule = .alwaysUp
            case .alwaysDown:
                rule = .alwaysDown
            }

            let rounded = roundedTotal(for: base, using: rule)

            let context: String
            switch band {
            case .upperElementary:
                context = "snacks at the school kiosk"
            case .middleSchool:
                context = "a small meal at the cafeteria"
            case .highSchool:
                context = "a quick stop at a café near school"
            }

            let question = """
            You buy \(context) and your total is \(formatCurrency(base)).
            The store uses the rule “\(rule.rawValue)”. If you pay with cash, what amount do you actually hand over after rounding?
            """

            let answerLine = "\(formatCurrency(base)) → \(formatCurrency(rounded))"

            result.append(
                WordProblem(
                    baseTotal: base,
                    rule: rule,
                    question: question,
                    answerLine: answerLine
                )
            )
        }

        return result
    }

    // MARK: - Helpers

    private func randomTotal(min: Double, max: Double) -> Double {
        let value = Double.random(in: min...max)
        return (value * 100).rounded() / 100.0
    }

    private func roundedTotal(for amount: Double, using rule: RoundingRule) -> Double {
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

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

// MARK: - Types

private enum GradeBand: String, CaseIterable, Identifiable {
    case upperElementary
    case middleSchool
    case highSchool

    var id: String { rawValue }

    var label: String {
        switch self {
        case .upperElementary: return "Gr 4–5"
        case .middleSchool:    return "Gr 6–8"
        case .highSchool:      return "HS"
        }
    }
}

private enum RuleMode: String, CaseIterable, Identifiable {
    case mixed
    case nearestFive
    case alwaysUp
    case alwaysDown

    var id: String { rawValue }

    var label: String {
        switch self {
        case .mixed:        return "Mixed"
        case .nearestFive:  return "Nearest"
        case .alwaysUp:     return "Up"
        case .alwaysDown:   return "Down"
        }
    }

    var explanation: String {
        switch self {
        case .mixed:
            return "Mix several rules so students must pay attention to which rule applies each time."
        case .nearestFive:
            return "Focus on the classic “nearest 5¢” rule, where some totals round up and some round down."
        case .alwaysUp:
            return "Model policies where stores always round up — ideal for discussions about fairness."
        case .alwaysDown:
            return "Model policies where customers always get the benefit of rounding down."
        }
    }
}

private struct WorksheetProblem: Identifiable {
    let id = UUID()
    let baseTotal: Double
    let rule: RoundingRule

    var prompt: String {
        let exact = formatCurrency(baseTotal)
        return "Total: \(exact). Using “\(rule.rawValue)”, what is the rounded cash total?"
    }

    var answerLine: String {
        let rounded = roundedTotal(for: baseTotal, using: rule)
        return "\(formatCurrency(baseTotal)) → \(formatCurrency(rounded))"
    }

    // Helpers scoped to this type so they don't clash with others

    private func roundedTotal(for amount: Double, using rule: RoundingRule) -> Double {
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

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }
}

private struct WordProblem: Identifiable {
    let id = UUID()
    let baseTotal: Double
    let rule: RoundingRule
    let question: String
    let answerLine: String
}
