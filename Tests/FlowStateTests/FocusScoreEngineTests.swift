// Tests/FlowStateTests/FocusScoreEngineTests.swift
import Testing
@testable import FlowState

@Suite("FocusScoreEngine Tests")
@MainActor
struct FocusScoreEngineTests {

    @Test("No activity produces zero score")
    func noActivityZeroScore() {
        let engine = FocusScoreEngine()
        let sample = ActivitySample(keystrokes: 0, mouseDistance: 0)
        engine.processSample(sample)
        let score = engine.currentScore
        #expect(score == 0)
    }

    @Test("Heavy typing produces high score")
    func heavyTypingHighScore() {
        let engine = FocusScoreEngine()
        let sample = ActivitySample(keystrokes: 10, mouseDistance: 50)
        engine.processSample(sample)
        let score = engine.currentScore
        #expect(score >= 70)
    }

    @Test("Heavy mouse use reduces score")
    func heavyMouseReducesScore() {
        let engine = FocusScoreEngine()
        let sample = ActivitySample(keystrokes: 5, mouseDistance: 600)
        engine.processSample(sample)
        let score = engine.currentScore
        #expect(score < 50)
    }

    @Test("Score decays over time without activity")
    func scoreDecaysWithoutActivity() {
        let engine = FocusScoreEngine()
        let activeSample = ActivitySample(keystrokes: 10, mouseDistance: 0)
        engine.processSample(activeSample)
        let initialScore = engine.currentScore

        let idleSample = ActivitySample(keystrokes: 0, mouseDistance: 0)
        for _ in 0..<10 {
            engine.processSample(idleSample)
        }
        let decayedScore = engine.currentScore

        #expect(decayedScore < initialScore)
    }
}
