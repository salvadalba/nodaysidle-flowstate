// Sources/FlowState/AppState.swift
import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    let focusEngine = FocusScoreEngine()
    let permissionChecker = AccessibilityPermissionChecker()
    let activityMonitor = ActivityMonitorService()
    let tintController = ScreenTintController()
    let idleDetector = IdleDetector()

    private(set) var lastKeystrokeCount: Int = 0
    private(set) var lastMouseDistance: Double = 0
    private var hasStarted = false

    var keystrokesActive: Bool { lastKeystrokeCount > 0 }
    var mouseActive: Bool { lastMouseDistance > 50 }
    var isTinting: Bool { tintController.isTinting }

    var menuBarImage: NSImage {
        MenuBarIconRenderer.render(score: focusEngine.currentScore)
    }

    func startTint() {
        tintController.show()
    }

    func clearTint() {
        tintController.hide()
        idleDetector.reset()  // Prevent immediate re-trigger
    }

    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        // Wire idle detector callbacks
        idleDetector.onIdleStart = { [weak self] in
            self?.tintController.show()
        }
        idleDetector.onIdleEnd = { [weak self] in
            self?.tintController.hide()
        }

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

        // Notify idle detector of score change
        idleDetector.update(score: focusEngine.currentScore)
    }
}
