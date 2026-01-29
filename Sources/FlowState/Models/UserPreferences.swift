// Sources/FlowState/Models/UserPreferences.swift
import Foundation
import SwiftUI

@MainActor
@Observable
final class UserPreferences {
    static let shared = UserPreferences()

    // MARK: - Focus Detection
    @ObservationIgnored
    @AppStorage("idleThreshold") var idleThreshold: Int = 30

    @ObservationIgnored
    @AppStorage("idleTriggerDuration") var idleTriggerDuration: Double = 10.0

    @ObservationIgnored
    @AppStorage("recoveryDuration") var recoveryDuration: Double = 5.0

    // MARK: - Screen Tint
    @ObservationIgnored
    @AppStorage("tintIntensity") var tintIntensity: Double = 0.6

    @ObservationIgnored
    @AppStorage("tintAnimationDuration") var tintAnimationDuration: Double = 30.0

    // MARK: - Break Suggestions
    @ObservationIgnored
    @AppStorage("breakPredictionEnabled") var breakPredictionEnabled: Bool = true

    @ObservationIgnored
    @AppStorage("defaultSessionLength") var defaultSessionLength: Double = 50.0  // minutes

    // MARK: - System
    @ObservationIgnored
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    private init() {}
}
