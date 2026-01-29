// Sources/FlowState/FlowStateApp.swift
import SwiftUI

@main
struct FlowStateApp: App {
    var body: some Scene {
        MenuBarExtra("FlowState", systemImage: "brain.head.profile") {
            Text("FlowState")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
