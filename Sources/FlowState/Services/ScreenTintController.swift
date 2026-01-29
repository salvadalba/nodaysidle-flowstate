// Sources/FlowState/Services/ScreenTintController.swift
import Cocoa

@MainActor
@Observable
final class ScreenTintController {
    private var overlay: ScreenTintOverlay?
    private(set) var isTinting: Bool = false

    private let animationDuration: TimeInterval = 30.0

    func show() {
        guard !isTinting else { return }

        isTinting = true

        // Create and show overlay
        let newOverlay = ScreenTintOverlay()
        newOverlay.orderFrontRegardless()
        newOverlay.animateDesaturation(duration: animationDuration)

        overlay = newOverlay
    }

    func hide() {
        guard isTinting else { return }

        overlay?.clearTint()
        overlay?.orderOut(nil)
        overlay = nil

        isTinting = false
    }
}
