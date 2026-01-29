// Sources/FlowState/FlowStateApp.swift
import SwiftUI

@main
struct FlowStateApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarDropdown(
                focusScore: appState.focusEngine.currentScore,
                hasPermission: appState.permissionChecker.hasPermission,
                keystrokesActive: appState.keystrokesActive,
                mouseActive: appState.mouseActive,
                isTinting: appState.isTinting,
                onOpenSettings: {
                    appState.permissionChecker.openSystemSettings()
                },
                onTestTint: {
                    appState.startTint()
                },
                onClearTint: {
                    appState.clearTint()
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
        } label: {
            Image(nsImage: appState.menuBarImage)
        }
        .menuBarExtraStyle(.window)
    }
}
