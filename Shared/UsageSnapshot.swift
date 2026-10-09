import Foundation

/// One usage meter (one ring in the widget).
struct UsageMeter: Codable, Hashable, Identifiable {
    var id: String
    var label: String
    /// SF Symbol shown in the middle of the ring.
    var symbol: String
    /// 0...100, nil when the meter doesn't apply (e.g. plan without Opus limit).
    var percent: Double?
    var resetsAt: Date?
}

enum SnapshotStatus: String, Codable {
    case ok
    case tokenMissing
    case tokenExpired
    case error
}

/// What the host app writes and the widget reads.
struct UsageSnapshot: Codable {
    var updatedAt: Date
    var status: SnapshotStatus
    var message: String?
    var plan: String?
    var claude: [UsageMeter]
    /// Reserved for phase 2.
    var openai: [UsageMeter]

    static let empty = UsageSnapshot(updatedAt: .distantPast, status: .error,
                                     message: "Abre AI Usage", plan: nil, claude: [], openai: [])

    static let preview = UsageSnapshot(
        updatedAt: .now, status: .ok, message: nil, plan: "pro",
        claude: [
            UsageMeter(id: "five_hour", label: "Sesión", symbol: "clock", percent: 55, resetsAt: .now.addingTimeInterval(3 * 3600)),
            UsageMeter(id: "seven_day", label: "Semana", symbol: "calendar", percent: 22, resetsAt: .now.addingTimeInterval(4 * 86400)),
            UsageMeter(id: "seven_day_opus", label: "Opus", symbol: "sparkles", percent: nil, resetsAt: nil),
        ],
        openai: [])
}

enum UsageLevel {
    case low, medium, high

    init(percent: Double) {
        switch percent {
        case ..<60: self = .low
        case ..<85: self = .medium
        default: self = .high
        }
    }
}

extension Date {
    /// "3h", "2d", "15m" — compact time until reset.
    func compactUntil(from now: Date = .now) -> String {
        let s = max(0, timeIntervalSince(now))
        if s >= 86400 { return "\(Int((s / 86400).rounded()))d" }
        if s >= 3600 { return "\(Int((s / 3600).rounded()))h" }
        return "\(Int((s / 60).rounded(.up)))m"
    }
}
