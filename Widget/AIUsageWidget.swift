import SwiftUI
import WidgetKit

struct UsageEntry: TimelineEntry {
    var date: Date
    var snapshot: UsageSnapshot
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (UsageEntry) -> Void) {
        let snap = context.isPreview ? .preview : (SharedStore.load() ?? .preview)
        completion(UsageEntry(date: .now, snapshot: snap))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UsageEntry>) -> Void) {
        // The host app pushes reloads every 5 min; this is only a fallback
        // so the "resets in" captions don't get too stale.
        let entry = UsageEntry(date: .now, snapshot: SharedStore.load() ?? .empty)
        completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60))))
    }
}

struct AIUsageWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: UsageEntry

    private var meters: [UsageMeter] { entry.snapshot.claude }
    private func meter(_ id: String) -> UsageMeter? { meters.first { $0.id == id } }

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .top, spacing: family == .systemSmall ? 10 : 14) {
                MeterColumn(meter: meter("five_hour"), placeholderSymbol: "clock")
                MeterColumn(meter: meter("seven_day"), placeholderSymbol: "calendar")
                if family != .systemSmall {
                    MeterColumn(meter: meter("seven_day_model"))
                    // Phase 2: OpenAI.
                    MeterColumn(meter: entry.snapshot.openai.first)
                }
            }
            if let note = statusNote {
                Text(note)
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                    .lineLimit(1)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var statusNote: String? {
        let s = entry.snapshot
        if s.status != .ok { return s.message ?? "Sin datos" }
        // Host app not running: data older than 30 min.
        if entry.date.timeIntervalSince(s.updatedAt) > 30 * 60 { return "Datos de \(s.updatedAt.formatted(date: .omitted, time: .shortened))" }
        return nil
    }
}

@main
struct AIUsageWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AIUsageWidget", provider: Provider()) { entry in
            AIUsageWidgetView(entry: entry)
        }
        .configurationDisplayName("AI Usage")
        .description("Uso de tu suscripción de Claude.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    AIUsageWidget()
} timeline: {
    UsageEntry(date: .now, snapshot: .preview)
}
