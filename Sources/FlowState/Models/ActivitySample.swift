// Sources/FlowState/Models/ActivitySample.swift
import Foundation

struct ActivitySample: Sendable {
    let keystrokes: Int
    let mouseDistance: Double
    let timestamp: Date

    init(keystrokes: Int = 0, mouseDistance: Double = 0, timestamp: Date = .now) {
        self.keystrokes = keystrokes
        self.mouseDistance = mouseDistance
        self.timestamp = timestamp
    }
}
