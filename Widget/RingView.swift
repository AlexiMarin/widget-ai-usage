import SwiftUI
import WidgetKit

extension UsageLevel {
    var color: Color {
        switch self {
        case .low: .green
        case .medium: .yellow
        case .high: .red
        }
    }
}

/// A Batteries-style ring: gray track, colored arc, icon in the middle.
struct RingView: View {
    var percent: Double?
    var symbol: String?
    var lineWidth: CGFloat = 7

    var body: some View {
        ZStack {
            Circle()
                .stroke(.primary.opacity(0.12), lineWidth: lineWidth)
            if let percent {
                Circle()
                    .trim(from: 0, to: max(0.005, min(percent, 100) / 100))
                    .stroke(UsageLevel(percent: percent).color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(lineWidth / 2)
    }
}

/// Ring + percentage + caption, one column of the widget.
struct MeterColumn: View {
    var meter: UsageMeter?
    var placeholderSymbol: String? = nil

    var body: some View {
        VStack(spacing: 6) {
            RingView(percent: meter?.percent, symbol: meter?.percent != nil ? meter?.symbol : placeholderSymbol)
                .aspectRatio(1, contentMode: .fit)
            if let m = meter, let p = m.percent {
                Text("\(Int(p.rounded()))%")
                    .font(.system(size: 15, weight: .medium))
                    .contentTransition(.numericText())
                Text(caption(m))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text(" ").font(.system(size: 15))
                Text(" ").font(.system(size: 10))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func caption(_ m: UsageMeter) -> String {
        guard let r = m.resetsAt else { return m.label }
        return "\(m.label) · \(r.compactUntil())"
    }
}
