// Sources/FlowState/FlowStateApp.swift
import SwiftUI

@main
struct FlowStateApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("FlowState", systemImage: "brain.head.profile") {
            MenuBarDropdown(
                focusScore: appState.focusEngine.currentScore,
                hasPermission: appState.permissionChecker.hasPermission,
                keystrokesActive: appState.keystrokesActive,
                mouseActive: appState.mouseActive,
                onOpenSettings: {
                    appState.permissionChecker.openSystemSettings()
                },
                onQuit: {
                    NSApplication.shared.terminate(nil)
                }
            )
            .onChange(of: appState.permissionChecker.hasPermission) { _, hasPermission in
                if hasPermission {
                    appState.startMonitoring()
                }
            }
            .task {
                appState.start()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
