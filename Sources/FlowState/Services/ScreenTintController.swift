// Sources/FlowState/Services/ScreenTintController.swift
import Cocoa
import SwiftUI

@MainActor
@Observable
final class ScreenTintController {
    private var overlays: [ScreenTintOverlay] = []
    private(set) var isTinting: Bool = false

    @ObservationIgnored
    @AppStorage("tintAnimationDuration") private var animationDuration: Double = 30.0

    @ObservationIgnored
    @AppStorage("tintIntensity") private var tintIntensity: Double = 0.6

    func show() {
        guard !isTinting else { return }

        isTinting = true

        // Create overlay for each screen
        for screen in NSScreen.screens {
            let overlay = ScreenTintOverlay(for: screen)
            overlay.orderFrontRegardless()
            overlay.animateDesaturation(duration: animationDuration, intensity: Float(tintIntensity))
            overlays.append(overlay)
        }
    }

    func hide() {
        guard isTinting else { return }

        for overlay in overlays {
            overlay.clearTint()
            overlay.orderOut(nil)
        }
        overlays.removeAll()

        isTinting = false
    }
}
