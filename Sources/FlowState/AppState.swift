// Sources/FlowState/AppState.swift
import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    let focusEngine = FocusScoreEngine()
    let permissionChecker = AccessibilityPermissionChecker()
    let activityMonitor = ActivityMonitorService()

    private(set) var lastKeystrokeCount: Int = 0
    private(set) var lastMouseDistance: Double = 0
    private var hasStarted = false

    var keystrokesActive: Bool { lastKeystrokeCount > 0 }
    var mouseActive: Bool { lastMouseDistance > 50 }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        permissionChecker.startPolling()

        if permissionChecker.hasPermission {
            startMonitoring()
        }
    }

    func startMonitoring() {
        Task {
            await activityMonitor.start { [weak self] sample in
                Task { @MainActor in
                    self?.handleSample(sample)
                }
            }
        }
    }

    func stopMonitoring() {
        Task {
            await activityMonitor.stop()
        }
    }

    private func handleSample(_ sample: ActivitySample) {
        lastKeystrokeCount = sample.keystrokes
        lastMouseDistance = sample.mouseDistance
        focusEngine.processSample(sample)
    }
}
