//
//  RoundingRule.swift
//  Pennywise
//
//  Core rounding rule model used across the app.
//  (No views in this file – just the enum + helpers.)
//

import Foundation

/// How cash totals should be rounded when pennies are removed.
enum RoundingRule: String, CaseIterable, Identifiable, Codable {
    /// Round to the *nearest* 5¢ (some totals go up, some go down).
    case nearestFive = "Nearest 5¢"
    /// Always round *up* to the next 5¢ (store-friendly).
    case alwaysUp    = "Always round up"
    /// Always round *down* to the previous 5¢ (customer-friendly).
    case alwaysDown  = "Always round down"

    // MARK: - Identity

    var id: String { rawValue }

    // MARK: - UI helpers

    /// Shorter label that can be used in segmented controls, etc.
    var shortLabel: String {
        switch self {
        case .nearestFive: return "Nearest"
        case .alwaysUp:    return "Up"
        case .alwaysDown:  return "Down"
        }
    }

    /// One-line explanation suitable for detail text or footnotes.
    var explanation: String {
        switch self {
        case .nearestFive:
            return "Totals are rounded to the nearest 5¢ — some go up, some go down."
        case .alwaysUp:
            return "Totals always round up to the next 5¢; customers never pay less than the exact total."
        case .alwaysDown:
            return "Totals always round down to the previous 5¢; customers never pay more than the exact total."
        }
    }

    /// Suggested SF Symbol for this rule (optional, for UI use).
    var systemImageName: String {
        switch self {
        case .nearestFive: return "arrow.up.arrow.down.circle"
        case .alwaysUp:    return "arrow.up.circle"
        case .alwaysDown:  return "arrow.down.circle"
        }
    }

    // MARK: - Rounding logic

    /// Apply this rounding rule to a dollar amount.
    ///
    /// - Parameter amount: A price in dollars (e.g. `12.73`).
    /// - Returns: A new price where the cents have been rounded to the nearest 5¢
    ///   according to the selected rule.
    func roundedTotal(for amount: Double) -> Double {
        // Don’t try to be clever with negative values.
        guard amount >= 0 else { return amount }

        // Work in cents for stability.
        let cents = (amount * 100).rounded()   // e.g. 12.73 ➜ 1273
        let nickels: Double

        switch self {
        case .nearestFive:
            // Divide by 5 to get “nickels”, round to nearest whole nickel.
            nickels = (cents / 5.0).rounded()
        case .alwaysUp:
            // Always round *up* to the next nickel.
            nickels = ceil(cents / 5.0)
        case .alwaysDown:
            // Always round *down* to the previous nickel.
            nickels = floor(cents / 5.0)
        }

        // Convert back to dollars.
        return nickels * 5.0 / 100.0
    }
}
