// Sources/FlowState/Services/IdleDetector.swift
import Foundation

@MainActor
@Observable
final class IdleDetector {
    private let lowThreshold: Int = 30
    private let idleTriggerDuration: TimeInterval = 10.0
    private let recoveryDuration: TimeInterval = 5.0

    private var belowThresholdSince: Date?
    private var aboveThresholdSince: Date?

    private(set) var isIdle: Bool = false

    var onIdleStart: (() -> Void)?
    var onIdleEnd: (() -> Void)?

    func update(score: Int) {
        let now = Date()

        if score < lowThreshold {
            // Below threshold
            aboveThresholdSince = nil

            if belowThresholdSince == nil {
                belowThresholdSince = now
            }

            // Check if we should trigger idle
            if !isIdle,
               let since = belowThresholdSince,
               now.timeIntervalSince(since) >= idleTriggerDuration {
                isIdle = true
                onIdleStart?()
            }
        } else {
            // Above threshold
            belowThresholdSince = nil

            if aboveThresholdSince == nil {
                aboveThresholdSince = now
            }

            // Check if we should clear idle
            if isIdle,
               let since = aboveThresholdSince,
               now.timeIntervalSince(since) >= recoveryDuration {
                isIdle = false
                onIdleEnd?()
            }
        }
    }

    func reset() {
        belowThresholdSince = nil
        aboveThresholdSince = nil
        isIdle = false
    }
}
