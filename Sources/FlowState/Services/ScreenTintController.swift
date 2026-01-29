// Sources/FlowState/Services/ScreenTintController.swift
import Cocoa

@MainActor
@Observable
final class ScreenTintController {
    private var overlays: [ScreenTintOverlay] = []
    private(set) var isTinting: Bool = false

    private let animationDuration: TimeInterval = 30.0

    func show() {
        guard !isTinting else { return }

        isTinting = true

        // Create overlay for each screen
        for screen in NSScreen.screens {
            let overlay = ScreenTintOverlay(for: screen)
            overlay.orderFrontRegardless()
            overlay.animateDesaturation(duration: animationDuration)
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
