//
//  PennyOpinionChoice 2.swift
//  Pennywise
//
//  Created by Bryan on 12/2/25.
//


//
//  PennyOpinionStore.swift
//  Pennywise
//
//  Local opinion poll store for “Keep / Retire / Unsure” about the penny.
//  Votes are stored on this device only using @AppStorage.
//

import SwiftUI
import Combine

// MARK: - Opinion choices

enum PennyOpinionChoice: String, CaseIterable, Identifiable {
    case keep
    case retire
    case unsure

    var id: String { rawValue }

    /// Full label used in result summaries.
    var label: String {
        switch self {
        case .keep:
            return "Keep the penny"
        case .retire:
            return "Retire the penny"
        case .unsure:
            return "Not sure yet"
        }
    }

    /// SF Symbol used in buttons and charts.
    var icon: String {
        switch self {
        case .keep:
            return "heart.circle.fill"
        case .retire:
            return "trash.circle.fill"
        case .unsure:
            return "questionmark.circle.fill"
        }
    }
}

// MARK: - Opinion store

@MainActor
final class PennyOpinionStore: ObservableObject {

    // Backing storage for votes (persisted on this device)
    @AppStorage("penny_keep_votes") private var keepVotesStorage: Int = 0
    @AppStorage("penny_retire_votes") private var retireVotesStorage: Int = 0
    @AppStorage("penny_unsure_votes") private var unsureVotesStorage: Int = 0

    /// Most recent choice tapped on this device.
    @Published private(set) var lastChoice: PennyOpinionChoice?

    // Public read-only accessors
    var keepVotes: Int { keepVotesStorage }
    var retireVotes: Int { retireVotesStorage }
    var unsureVotes: Int { unsureVotesStorage }

    /// Total votes recorded on this device.
    var totalVotes: Int {
        keepVotes + retireVotes + unsureVotes
    }

    // MARK: - API

    /// Returns the vote count for a specific choice.
    func votes(for choice: PennyOpinionChoice) -> Int {
        switch choice {
        case .keep:
            return keepVotes
        case .retire:
            return retireVotes
        case .unsure:
            return unsureVotes
        }
    }

    /// Records a vote for the given choice.
    func vote(_ choice: PennyOpinionChoice) {
        switch choice {
        case .keep:
            keepVotesStorage += 1
        case .retire:
            retireVotesStorage += 1
        case .unsure:
            unsureVotesStorage += 1
        }

        lastChoice = choice

        // Force ObservableObject updates because @AppStorage
        // does not automatically trigger objectWillChange.
        objectWillChange.send()
    }

    /// Returns the percentage of total votes for a choice, from 0–100.
    func percentage(for choice: PennyOpinionChoice) -> Double {
        let total = Double(totalVotes)
        guard total > 0 else { return 0 }
        return (Double(votes(for: choice)) / total) * 100.0
    }

    /// Optional helper to clear all local votes (useful for debugging or
    /// a “Reset poll on this device” action, if you decide to expose one).
    func resetAllVotes() {
        keepVotesStorage = 0
        retireVotesStorage = 0
        unsureVotesStorage = 0
        lastChoice = nil
        objectWillChange.send()
    }
}
