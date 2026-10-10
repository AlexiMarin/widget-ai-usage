import SwiftUI
import WidgetKit

struct UsageEntry: TimelineEntry {
    var date: Date
    var snapshot: UsageSnapshot
    var provider: AIProvider = .claude
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> UsageEntry {
        UsageEntry(date: .now, snapshot: .preview)
    }

    func snapshot(for configuration: SelectProviderIntent, in context: Context) async -> UsageEntry {
        let snap = context.isPreview ? .preview : (SharedStore.load() ?? .preview)
        return UsageEntry(date: .now, snapshot: snap, provider: configuration.provider)
    }

    func timeline(for configuration: SelectProviderIntent, in context: Context) async -> Timeline<UsageEntry> {
        // The host app pushes reloads every 5 min; this is only a fallback
        // so the "data from" note doesn't get too stale.
        let entry = UsageEntry(date: .now, snapshot: SharedStore.load() ?? .empty, provider: configuration.provider)
        return Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60)))
    }
}

struct AIUsageWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: UsageEntry

    /// The two headline windows: session and week.
    private var meters: [UsageMeter] {
        Array(entry.provider.meters(in: entry.snapshot).prefix(2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.provider.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 16)
            HStack(alignment: .top, spacing: 17) {
                if meters.isEmpty {
                    MeterColumn(meter: nil, placeholderSymbol: "clock")
                    MeterColumn(meter: nil, placeholderSymbol: "calendar")
                } else {
                    ForEach(meters) { MeterColumn(meter: $0) }
                }
                if family == .systemMedium {
                    // Batteries-style empty slots so the medium widget keeps four columns.
                    ForEach(0..<(4 - max(meters.count, 2)), id: \.self) { _ in MeterColumn(meter: nil) }
                }
            }
            .frame(maxWidth: .infinity)
            if let note = statusNote {
                Text(note)
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var statusNote: String? {
        let s = entry.snapshot
        switch entry.provider {
        case .openai:
            return s.openai.isEmpty ? "Próximamente" : nil
        case .claude:
            if s.status != .ok { return s.message ?? "Sin datos" }
            // Host app not running: data older than 30 min.
            if entry.date.timeIntervalSince(s.updatedAt) > 30 * 60 { return "Datos de \(s.updatedAt.formatted(date: .omitted, time: .shortened))" }
            return nil
        }
    }
}

@main
struct AIUsageWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "AIUsageWidget", intent: SelectProviderIntent.self, provider: Provider()) { entry in
            AIUsageWidgetView(entry: entry)
        }
        .configurationDisplayName("AI Usage")
        .description("Uso de tu suscripción. Edita el widget para elegir el proveedor.")
        // Batteries-size rings don't fit two-up inside the default small-widget margins.
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    AIUsageWidget()
} timeline: {
    UsageEntry(date: .now, snapshot: .preview)
}
