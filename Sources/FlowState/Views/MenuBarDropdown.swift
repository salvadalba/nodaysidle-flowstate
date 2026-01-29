// Sources/FlowState/Views/MenuBarDropdown.swift
import SwiftUI

struct MenuBarDropdown: View {
    let focusScore: Int
    let hasPermission: Bool
    let keystrokesActive: Bool
    let mouseActive: Bool
    let isTinting: Bool
    let onOpenSettings: () -> Void
    let onTestTint: () -> Void
    let onClearTint: () -> Void
    let onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if hasPermission {
                scoreView
            } else {
                permissionRequestView
            }

            Divider()

            Button("Quit FlowState") {
                onQuit()
            }
        }
        .padding()
        .frame(width: 220)
    }

    private var scoreView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Focus Score")
                .font(.headline)

            HStack {
                ProgressView(value: Double(focusScore), total: 100)
                    .progressViewStyle(.linear)

                Text("\(focusScore)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .frame(width: 40, alignment: .trailing)
            }

            HStack(spacing: 16) {
                Label(
                    keystrokesActive ? "Keyboard: Active" : "Keyboard: Idle",
                    systemImage: keystrokesActive ? "keyboard.fill" : "keyboard"
                )
                .foregroundColor(keystrokesActive ? .green : .secondary)

                Label(
                    mouseActive ? "Mouse: Active" : "Mouse: Idle",
                    systemImage: mouseActive ? "computermouse.fill" : "computermouse"
                )
                .foregroundColor(mouseActive ? .orange : .secondary)
            }
            .font(.caption)

            Divider()

            tintControlsView

            Divider()
        }
    }

    private var tintControlsView: some View {
        HStack(spacing: 12) {
            Button("Test Tint") {
                onTestTint()
            }
            .disabled(isTinting)

            Button("Clear Tint") {
                onClearTint()
            }
            .disabled(!isTinting)
        }
        .buttonStyle(.bordered)
    }

    private var permissionRequestView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Accessibility Access Required", systemImage: "lock.shield")
                .font(.headline)

            Text("FlowState needs Accessibility access to monitor keyboard and mouse activity for focus detection.")
                .font(.caption)
                .foregroundColor(.secondary)

            Button("Open System Settings") {
                onOpenSettings()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview("With Permission") {
    MenuBarDropdown(
        focusScore: 78,
        hasPermission: true,
        keystrokesActive: true,
        mouseActive: false,
        isTinting: false,
        onOpenSettings: {},
        onTestTint: {},
        onClearTint: {},
        onQuit: {}
    )
}

#Preview("Without Permission") {
    MenuBarDropdown(
        focusScore: 0,
        hasPermission: false,
        keystrokesActive: false,
        mouseActive: false,
        isTinting: false,
        onOpenSettings: {},
        onTestTint: {},
        onClearTint: {},
        onQuit: {}
    )
}
