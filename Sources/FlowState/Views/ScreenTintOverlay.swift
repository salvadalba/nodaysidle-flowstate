// Sources/FlowState/Views/ScreenTintOverlay.swift
import Cocoa
import QuartzCore

final class ScreenTintOverlay: NSPanel {
    private let overlayView: NSView
    private let colorFilter: CIFilter

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init() {
        // Create desaturation filter
        colorFilter = CIFilter(name: "CIColorControls")!
        colorFilter.setValue(1.0, forKey: kCIInputSaturationKey) // Start with full color

        // Create overlay view
        overlayView = NSView()
        overlayView.wantsLayer = true
        overlayView.layer?.backgroundColor = NSColor.black.cgColor
        overlayView.layer?.opacity = 0

        // Get main screen size
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        super.init(
            contentRect: screenFrame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        // Configure panel
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.hasShadow = false

        // Add overlay view
        self.contentView = overlayView
        overlayView.frame = screenFrame
    }

    func setSaturation(_ saturation: CGFloat) {
        // saturation: 1.0 = full color, 0.0 = grayscale
        // We invert to opacity: 0.0 = invisible, 0.7 = visible gray overlay
        let opacity = Float((1.0 - saturation) * 0.7)
        overlayView.layer?.opacity = opacity
    }

    func animateDesaturation(duration: TimeInterval) {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.0
        animation.toValue = 0.7
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        overlayView.layer?.add(animation, forKey: "desaturation")
        overlayView.layer?.opacity = 0.7
    }

    func clearTint() {
        overlayView.layer?.removeAllAnimations()
        overlayView.layer?.opacity = 0
    }
}
