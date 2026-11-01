//
//  LearnTeachView.swift
//  Pennywise
//
//  Classroom-focused explanations about pennies, rounding,
//  and fairness, free for teachers and students.
//

import SwiftUI
import Combine

@MainActor
struct LearnTeachView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        PennyScreenBackground(
            title: "Learn & Teach",
            subtitle: "Classroom-friendly explanations about pennies, inflation, and why the smallest coin can spark big questions."
        ) {
            VStack(alignment: .leading, spacing: 20) {
                teacherIntroBanner
                basicsCard
                mathCard
                debateCard
                teacherResourcesCard
            }
        }
    }

    // MARK: - “Free for teachers” banner

    private var teacherIntroBanner: some View {
        PennyCard {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "graduationcap.fill")
                    .font(.title2)
                    .foregroundColor(PennyTheme.accentCopper)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Built for real classrooms")
                        .font(.headline)
                    Text("Pennywise is designed so you can put it on a projector, tablet, or phone and start talking about coins, rounding, and fairness right away.")
                        .font(.footnote)
                        .foregroundColor(PennyTheme.secondaryText(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Core cards

    private var basicsCard: some View {
        PennyCard(title: "What’s happening to the penny?") {
            VStack(alignment: .leading, spacing: 8) {
                BulletPoint(text: "It costs more than 1¢ to make a 1¢ coin. In 2024, each penny cost about 3.7¢ to produce and distribute.")
                BulletPoint(text: "Pennies are used less often in everyday purchases as prices rise and more people pay with cards.")
                BulletPoint(text: "Other countries have already retired their smallest coins and now round totals to the nearest 5 or 10 cents.")

                Text("The core tension is simple: the penny still exists in prices and habits, but the government spends several cents to make each 1¢ coin.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .padding(.top, 6)
            }
        }
    }

    private var mathCard: some View {
        PennyCard(title: "Rounding as a math lesson") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Penny rounding turns into a concrete way to practice decimals and number sense.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                BulletPoint(text: "Rounding totals to the nearest 5¢ instead of the nearest whole dollar.")
                BulletPoint(text: "Seeing how 1–2¢ go one way and 3–4¢ go another in a symmetric rule.")
                BulletPoint(text: "Comparing different rules (nearest 5¢, always up, always down) and asking which feels fair.")

                Text("Quick activity: give each student a short list of prices, then ask them to calculate the new total at the register if the store rounds to the nearest 5¢.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .padding(.top, 6)
            }
        }
    }

    private var debateCard: some View {
        PennyCard(title: "Mini debate kit") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Two clear positions:")
                    .font(.footnote.bold())
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                BulletPoint(text: "“Retire the penny” — it costs more than it is worth, slows down lines, and rounding barely changes totals on average.")
                BulletPoint(text: "“Keep the penny” — rounding might bother cash users, and the penny has symbolic and charitable value.")

                Text("Discussion prompts:")
                    .font(.footnote.bold())
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .padding(.top, 6)

                BulletPoint(text: "Is it reasonable to stop making a coin if it costs more than its own value to produce?")
                BulletPoint(text: "Who might feel rounding most — people who mostly use cards or people who mostly use cash?")
                BulletPoint(text: "If your class had to vote, what rounding rule would you choose and why?")
            }
        }
    }

    // MARK: - Extra “teacher resources” card

    private var teacherResourcesCard: some View {
        PennyCard(title: "Ideas for teachers") {
            VStack(alignment: .leading, spacing: 8) {
                Text("A few ways to fit Pennywise into an existing lesson:")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))

                BulletPoint(text: "Use the “Everyday Impact” tab while students suggest prices to test live on the board.")
                BulletPoint(text: "Let students explore the “Economics” tab in pairs, then write a short summary of what surprised them.")
                BulletPoint(text: "Run a simple class vote on whether to keep or retire the penny, then compare results across different groups or grade levels.")

                Text("You can always pair the app with your own worksheets, quizzes, or writing prompts so students have both a visual and a written record of what they learned.")
                    .font(.footnote)
                    .foregroundColor(PennyTheme.secondaryText(scheme))
                    .padding(.top, 6)
            }
        }
    }
}
