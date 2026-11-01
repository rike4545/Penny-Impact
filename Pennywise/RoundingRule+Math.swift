//
//  RoundingRule+Math.swift
//  Pennywise
//

import Foundation

extension RoundingRule: Codable {}

extension RoundingRule {
    /// Apply this rounding rule to a total amount.
    /// Assumes prices are in dollars (e.g. 12.34).
    func roundedTotal(for amount: Double) -> Double {
        guard amount >= 0 else { return amount }

        let cents = Int((amount * 100.0).rounded()) // whole cents
        let remainder = cents % 5

        switch self {
        case .nearestFive:
            let down = cents - remainder
            let up   = remainder == 0 ? cents : cents + (5 - remainder)
            let nearest = (cents - down) <= (up - cents) ? down : up
            return Double(nearest) / 100.0

        case .alwaysUp:
            let rounded = remainder == 0 ? cents : cents + (5 - remainder)
            return Double(rounded) / 100.0

        case .alwaysDown:
            let rounded = cents - remainder
            return Double(rounded) / 100.0
        }
    }
}
