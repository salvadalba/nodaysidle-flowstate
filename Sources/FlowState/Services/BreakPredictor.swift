// Sources/FlowState/Services/BreakPredictor.swift
import Foundation
import SwiftUI

@MainActor
@Observable
final class BreakPredictor {
    private let dataStore: ActivityDataStore

    private(set) var shouldSuggestBreak = false
    private(set) var predictedOptimalDuration: TimeInterval = 50 * 60  // Default 50 min

    private var lastPredictionTime: Date?
    private let predictionInterval: TimeInterval = 60  // Check every minute

    @ObservationIgnored
    @AppStorage("breakPredictionEnabled") private var isEnabled: Bool = true

    @ObservationIgnored
    @AppStorage("defaultSessionLength") private var defaultSessionLength: Double = 50.0

    var onBreakSuggested: (() -> Void)?

    init(dataStore: ActivityDataStore) {
        self.dataStore = dataStore
        predictedOptimalDuration = defaultSessionLength * 60
        Task {
            await updateOptimalDuration()
        }
    }

    func update(sessionDuration: TimeInterval, averageScore: Double, trend: Double) {
        guard isEnabled else {
            shouldSuggestBreak = false
            return
        }

        let now = Date()

        // Only predict every minute
        if let last = lastPredictionTime, now.timeIntervalSince(last) < predictionInterval {
            return
        }
        lastPredictionTime = now

        // Predict if break should be suggested
        let probability = calculateBreakProbability(
            duration: sessionDuration,
            avgScore: averageScore,
            trend: trend
        )

        let previousState = shouldSuggestBreak
        shouldSuggestBreak = probability > 0.7

        if shouldSuggestBreak && !previousState {
            onBreakSuggested?()
        }
    }

    func dismissSuggestion() {
        shouldSuggestBreak = false
    }

    func recordOutcome(followed: Bool) {
        // Adjust optimal duration based on outcome
        Task {
            await updateOptimalDuration()
        }
    }

    private func calculateBreakProbability(duration: TimeInterval, avgScore: Double, trend: Double) -> Double {
        // Adaptive heuristic model
        var probability = 0.0

        // Factor 1: Duration relative to optimal
        let durationRatio = duration / predictedOptimalDuration
        if durationRatio > 1.0 {
            probability += min(0.5, (durationRatio - 1.0) * 0.5)
        } else if durationRatio > 0.8 {
            probability += (durationRatio - 0.8) * 0.25
        }

        // Factor 2: Declining focus (negative trend)
        if trend < -10 {
            probability += 0.3
        } else if trend < -5 {
            probability += 0.15
        }

        // Factor 3: Low average score in recent period
        if avgScore < 40 {
            probability += 0.2
        }

        return min(1.0, probability)
    }

    private func updateOptimalDuration() async {
        let sessions = await dataStore.getAllSessions()

        // Filter to natural breaks with reasonable duration
        let naturalSessions = sessions.filter { session in
            session.duration > 10 * 60 &&  // At least 10 min
            session.duration < 180 * 60 && // Less than 3 hours
            (session.suggestionWasFollowed == nil || session.suggestionWasFollowed == true)
        }

        guard naturalSessions.count >= 3 else { return }

        // Calculate weighted average (recent sessions weighted more)
        let sortedSessions = naturalSessions.sorted { $0.startTime > $1.startTime }
        var weightedSum = 0.0
        var weightSum = 0.0

        for (index, session) in sortedSessions.prefix(10).enumerated() {
            let weight = 1.0 / Double(index + 1)
            weightedSum += session.duration * weight
            weightSum += weight
        }

        if weightSum > 0 {
            predictedOptimalDuration = weightedSum / weightSum
        }
    }
}
