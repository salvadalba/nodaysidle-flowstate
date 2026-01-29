// Sources/FlowState/Services/FocusScoreEngine.swift
import Foundation
import Observation

@Observable
@MainActor
final class FocusScoreEngine {
    private(set) var currentScore: Int = 0
    private var previousScore: Double = 0

    private let decayFactor: Double = 0.977

    func processSample(_ sample: ActivitySample) {
        let instantScore = calculateInstantScore(sample)

        let decayedPrevious = previousScore * decayFactor
        let newScore = max(Double(instantScore), decayedPrevious)

        previousScore = newScore
        currentScore = Int(newScore.rounded())
    }

    private func calculateInstantScore(_ sample: ActivitySample) -> Int {
        let keyboardScore: Int
        switch sample.keystrokes {
        case 0:
            keyboardScore = 0
        case 1...3:
            keyboardScore = 30
        case 4...8:
            keyboardScore = 50
        default:
            keyboardScore = 70
        }

        let mousePenalty: Int
        switch sample.mouseDistance {
        case ..<100:
            mousePenalty = 0
        case 100..<500:
            mousePenalty = -10
        default:
            mousePenalty = -20
        }

        let idleBonus = (sample.keystrokes > 0 && sample.mouseDistance < 100) ? 10 : 0

        let total = keyboardScore + mousePenalty + idleBonus
        return max(0, min(100, total))
    }

    func reset() {
        currentScore = 0
        previousScore = 0
    }
}
