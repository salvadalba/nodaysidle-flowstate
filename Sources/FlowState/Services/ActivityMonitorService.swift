// Sources/FlowState/Services/ActivityMonitorService.swift
import Foundation
import Cocoa
import IOKit.hid

/// Monitors keyboard and mouse activity using IOKit HID and NSEvent.
/// Emits ActivitySample values at 1-second intervals.
actor ActivityMonitorService {
    private var hidManager: IOHIDManager?
    private var sampleCallback: (@Sendable (ActivitySample) -> Void)?
    private var sampleTask: Task<Void, Never>?
    private var sharedState: SharedActivityState?

    var isRunning: Bool {
        hidManager != nil
    }

    func start(onSample: @escaping @Sendable (ActivitySample) -> Void) async {
        guard hidManager == nil else { return }

        sampleCallback = onSample

        // Create shared state for thread-safe communication
        let state = SharedActivityState()
        sharedState = state

        // Create HID manager
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

        guard let manager = hidManager else { return }

        // Match keyboard and mouse devices
        let keyboardCriteria: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Keyboard
        ]

        let mouseCriteria: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey as String: kHIDUsage_GD_Mouse
        ]

        IOHIDManagerSetDeviceMatchingMultiple(manager, [keyboardCriteria, mouseCriteria] as CFArray)

        // Set up input callback
        let unmanagedState = Unmanaged.passRetained(state)

        let callback: IOHIDValueCallback = { context, _, _, value in
            guard let context = context else { return }
            let sharedState = Unmanaged<SharedActivityState>.fromOpaque(context).takeUnretainedValue()

            let element = IOHIDValueGetElement(value)
            let usagePage = IOHIDElementGetUsagePage(element)

            if usagePage == kHIDPage_KeyboardOrKeypad {
                sharedState.incrementKeystrokes()
            }
        }

        IOHIDManagerRegisterInputValueCallback(manager, callback, unmanagedState.toOpaque())
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))

        // Start mouse tracking on main thread
        await MainActor.run {
            let monitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { _ in
                let location = NSEvent.mouseLocation
                state.recordMouseMove(to: location)
            }
            state.setMouseMonitor(monitor)
        }

        // Start sampling task
        sampleTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))

                guard let self = self, !Task.isCancelled else { break }

                // Collect data from shared state
                let keystrokes = state.getAndResetKeystrokes()
                let distance = state.getAndResetMouseDistance()

                let sample = ActivitySample(
                    keystrokes: keystrokes,
                    mouseDistance: distance
                )

                await self.emitSample(sample)
            }

            // Clean up the retained reference when done
            unmanagedState.release()
        }
    }

    private func emitSample(_ sample: ActivitySample) {
        sampleCallback?(sample)
    }

    func stop() async {
        // Cancel sampling task
        sampleTask?.cancel()
        sampleTask = nil

        // Remove mouse monitor on main thread
        if let state = sharedState, let monitor = state.getMouseMonitor() {
            await MainActor.run {
                NSEvent.removeMonitor(monitor)
            }
        }
        sharedState = nil

        // Close HID manager
        if let manager = hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            hidManager = nil
        }

        sampleCallback = nil
    }
}

// MARK: - Thread-Safe Shared State

/// A thread-safe class for collecting activity data from C callbacks.
/// Uses atomic operations via locks for safe cross-thread access.
private final class SharedActivityState: @unchecked Sendable {
    private let lock = NSLock()
    private var keystrokeCount: Int = 0
    private var mouseDistance: Double = 0
    private var lastMouseLocation: CGPoint?
    private var mouseMonitor: Any?

    func incrementKeystrokes() {
        lock.withLock {
            keystrokeCount += 1
        }
    }

    func recordMouseMove(to point: CGPoint) {
        lock.withLock {
            if let last = lastMouseLocation {
                let dx = point.x - last.x
                let dy = point.y - last.y
                mouseDistance += sqrt(dx * dx + dy * dy)
            }
            lastMouseLocation = point
        }
    }

    func getAndResetKeystrokes() -> Int {
        lock.withLock {
            let count = keystrokeCount
            keystrokeCount = 0
            return count
        }
    }

    func getAndResetMouseDistance() -> Double {
        lock.withLock {
            let distance = mouseDistance
            mouseDistance = 0
            return distance
        }
    }

    func setMouseMonitor(_ monitor: Any?) {
        lock.withLock {
            mouseMonitor = monitor
        }
    }

    func getMouseMonitor() -> Any? {
        lock.withLock {
            return mouseMonitor
        }
    }
}
