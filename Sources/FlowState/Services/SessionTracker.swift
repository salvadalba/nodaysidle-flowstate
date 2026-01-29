// Sources/FlowState/Services/SessionTracker.swift
import Foundation

@MainActor
@Observable
final class SessionTracker {
    private let dataStore: ActivityDataStore

    private var sessionStartTime: Date?
    private var sessionSamples: [(score: Int, timestamp: Date)] = []
    private var breakWasSuggested = false

    private let focusThreshold = 50
    private let startDuration: TimeInterval = 30  // 30 seconds above threshold to start

    private var aboveThresholdSince: Date?

    private(set) var isInSession = false
    private(set) var currentSessionDuration: TimeInterval = 0
    private(set) var currentSessionAverageScore: Double = 0

    init(dataStore: ActivityDataStore) {
        self.dataStore = dataStore
    }

    func update(score: Int, sample: ActivitySample) {
        // Store sample
        Task {
            await dataStore.addSample(sample, focusScore: score)
        }

        let now = Date()

        if isInSession {
            // Track session data
            sessionSamples.append((score: score, timestamp: now))
            currentSessionDuration = now.timeIntervalSince(sessionStartTime ?? now)
            currentSessionAverageScore = sessionSamples.isEmpty ? 0 :
                Double(sessionSamples.map(\.score).reduce(0, +)) / Double(sessionSamples.count)
        } else {
            // Check if session should start
            if score >= focusThreshold {
                if aboveThresholdSince == nil {
                    aboveThresholdSince = now
                }

                if let since = aboveThresholdSince,
                   now.timeIntervalSince(since) >= startDuration {
                    startSession(at: since)
                }
            } else {
                aboveThresholdSince = nil
            }
        }
    }

    func markBreakSuggested() {
        breakWasSuggested = true
    }

    func endSession(suggestionFollowed: Bool?) {
        guard isInSession, let startTime = sessionStartTime else { return }

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let avgScore = currentSessionAverageScore
        let peakScore = sessionSamples.map(\.score).max() ?? 0

        // Calculate activity trend (compare last quarter to first quarter)
        let trend = calculateActivityTrend()

        let calendar = Calendar.current
        let record = SessionRecord(
            id: UUID(),
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            averageFocusScore: avgScore,
            peakFocusScore: peakScore,
            activityTrend: trend,
            hourOfDay: calendar.component(.hour, from: startTime),
            dayOfWeek: calendar.component(.weekday, from: startTime),
            breakWasSuggested: breakWasSuggested,
            suggestionWasFollowed: suggestionFollowed
        )

        Task {
            await dataStore.addSession(record)
        }

        resetSession()
    }

    private func startSession(at time: Date) {
        isInSession = true
        sessionStartTime = time
        sessionSamples = []
        breakWasSuggested = false
        currentSessionDuration = 0
        currentSessionAverageScore = 0
    }

    private func resetSession() {
        isInSession = false
        sessionStartTime = nil
        sessionSamples = []
        breakWasSuggested = false
        currentSessionDuration = 0
        currentSessionAverageScore = 0
        aboveThresholdSince = nil
    }

    private func calculateActivityTrend() -> Double {
        guard sessionSamples.count >= 4 else { return 0 }

        let quarterSize = sessionSamples.count / 4
        let firstQuarter = sessionSamples.prefix(quarterSize)
        let lastQuarter = sessionSamples.suffix(quarterSize)

        let firstAvg = Double(firstQuarter.map(\.score).reduce(0, +)) / Double(firstQuarter.count)
        let lastAvg = Double(lastQuarter.map(\.score).reduce(0, +)) / Double(lastQuarter.count)

        return lastAvg - firstAvg
    }
}
