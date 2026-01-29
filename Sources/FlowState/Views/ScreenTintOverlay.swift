// Sources/FlowState/Views/ScreenTintOverlay.swift
import Cocoa
import QuartzCore

final class ScreenTintOverlay: NSPanel {
    private let overlayView: NSView

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(for screen: NSScreen) {
        // Use bounds (local coordinates) for the view, not frame (global coordinates)
        let bounds = NSRect(origin: .zero, size: screen.frame.size)
        overlayView = NSView(frame: bounds)

        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Configure panel
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.hasShadow = false
        self.hidesOnDeactivate = false

        // Set content view
        self.contentView = overlayView
        overlayView.autoresizingMask = [.width, .height]

        // Configure layer AFTER view is added to window
        overlayView.wantsLayer = true
        overlayView.layer?.backgroundColor = NSColor.gray.cgColor
        overlayView.layer?.opacity = 0
    }

    func animateDesaturation(duration: TimeInterval) {
        guard let layer = overlayView.layer else { return }

        // Set model value first
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.opacity = 0.0
        CATransaction.commit()

        // Then animate
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.0
        animation.toValue = 0.6
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        layer.add(animation, forKey: "desaturation")
    }

    func clearTint() {
        guard let layer = overlayView.layer else { return }
        layer.removeAllAnimations()

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.opacity = 0
        CATransaction.commit()
    }
}
