// Sources/FlowState/Services/ActivityDataStore.swift
import Foundation

struct StoredActivitySample: Codable, Sendable {
    let timestamp: Date
    let keystrokes: Int
    let mouseDistance: Double
    let focusScore: Int
}

struct SessionRecord: Codable, Sendable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let averageFocusScore: Double
    let peakFocusScore: Int
    let activityTrend: Double  // positive = rising, negative = falling
    let hourOfDay: Int
    let dayOfWeek: Int
    let breakWasSuggested: Bool
    let suggestionWasFollowed: Bool?
}

actor ActivityDataStore {
    private let samplesFileURL: URL
    private let sessionsFileURL: URL
    private var recentSamples: [StoredActivitySample] = []
    private var sessions: [SessionRecord] = []

    private let maxSampleAge: TimeInterval = 7 * 24 * 60 * 60  // 7 days

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let flowStateDir = appSupport.appendingPathComponent("FlowState", isDirectory: true)

        try? FileManager.default.createDirectory(at: flowStateDir, withIntermediateDirectories: true)

        samplesFileURL = flowStateDir.appendingPathComponent("activity_samples.json")
        sessionsFileURL = flowStateDir.appendingPathComponent("sessions.json")

        // Load data synchronously using nonisolated helper
        let (samples, loadedSessions) = Self.loadDataSync(
            samplesURL: samplesFileURL,
            sessionsURL: sessionsFileURL
        )
        recentSamples = samples
        sessions = loadedSessions
    }

    private nonisolated static func loadDataSync(
        samplesURL: URL,
        sessionsURL: URL
    ) -> ([StoredActivitySample], [SessionRecord]) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        var samples: [StoredActivitySample] = []
        var sessions: [SessionRecord] = []

        if let data = try? Data(contentsOf: samplesURL),
           let loaded = try? decoder.decode([StoredActivitySample].self, from: data) {
            let cutoff = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            samples = loaded.filter { $0.timestamp >= cutoff }
        }

        if let data = try? Data(contentsOf: sessionsURL),
           let loaded = try? decoder.decode([SessionRecord].self, from: data) {
            sessions = loaded
        }

        return (samples, sessions)
    }

    func addSample(_ sample: ActivitySample, focusScore: Int) {
        let stored = StoredActivitySample(
            timestamp: sample.timestamp,
            keystrokes: sample.keystrokes,
            mouseDistance: sample.mouseDistance,
            focusScore: focusScore
        )
        recentSamples.append(stored)

        // Prune old samples periodically
        if recentSamples.count % 100 == 0 {
            pruneOldSamples()
        }
    }

    func addSession(_ session: SessionRecord) {
        sessions.append(session)
        saveData()
    }

    func getRecentSamples(since: Date) -> [StoredActivitySample] {
        recentSamples.filter { $0.timestamp >= since }
    }

    func getAllSessions() -> [SessionRecord] {
        sessions
    }

    func saveData() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if let samplesData = try? encoder.encode(recentSamples) {
            try? samplesData.write(to: samplesFileURL)
        }
        if let sessionsData = try? encoder.encode(sessions) {
            try? sessionsData.write(to: sessionsFileURL)
        }
    }

    private func pruneOldSamples() {
        let cutoff = Date().addingTimeInterval(-maxSampleAge)
        recentSamples = recentSamples.filter { $0.timestamp >= cutoff }
    }
}
