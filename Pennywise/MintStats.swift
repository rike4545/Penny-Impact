//
//  MintStats.swift
//  Pennywise
//
//  Uses recent U.S. Mint data (2022–2024), including the
//  2024 figure: 3.7¢ per penny.
//

import SwiftUI
import Combine

struct MintStats: Codable, Identifiable {
    let year: Int
    let unitCostCents: Double
    let unitsProduced: Double   // number of pennies

    var id: Int { year }

    var unitCostDollars: Double { unitCostCents / 100.0 }
    var faceValueDollars: Double { 0.01 }

    /// Net loss from pennies in this year (if cost > face value).
    var annualLossDollars: Double {
        max(unitCostDollars - faceValueDollars, 0) * unitsProduced
    }

    var annualLossMillions: Double {
        annualLossDollars / 1_000_000.0
    }
}

@MainActor
final class MintStatsStore: ObservableObject {
    @Published var stats: [MintStats] = []
    @Published var selectedYear: Int?

    init() {
        load()
    }

    private func load() {
        // Try to load from a bundled JSON file named mint_stats.json.
        // If it is missing or invalid, fall back to built-in values
        // based on 2022–2024 U.S. Mint reports.
        if let url = Bundle.main.url(forResource: "mint_stats", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([MintStats].self, from: data)
                self.stats = decoded.sorted { $0.year < $1.year }
                self.selectedYear = decoded.last?.year
                return
            } catch {
                print("MintStatsStore: Failed to load mint_stats.json, using built-in data. Error: \(error)")
            }
        }

        // Built-in dataset if JSON is unavailable:
        // 2022: 2.72¢; 2023: 3.07¢; 2024: 3.70¢
        self.stats = [
            MintStats(year: 2022, unitCostCents: 2.72, unitsProduced: 6_359_600_000),
            MintStats(year: 2023, unitCostCents: 3.07, unitsProduced: 4_522_800_000),
            MintStats(year: 2024, unitCostCents: 3.70, unitsProduced: 3_225_200_000)
        ]
        self.selectedYear = stats.last?.year
    }

    var currentStat: MintStats? {
        guard let year = selectedYear else { return stats.last }
        return stats.first(where: { $0.year == year }) ?? stats.last
    }
}
