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
    var lineWidth: CGFloat = 6

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
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(lineWidth / 2)
    }
}

/// Ring + percentage, one column of the widget (Batteries proportions).
struct MeterColumn: View {
    var meter: UsageMeter?
    var placeholderSymbol: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            RingView(percent: meter?.percent, symbol: meter?.percent != nil ? meter?.symbol : placeholderSymbol)
                .frame(width: 64, height: 64)
            Text(meter?.percent.map { "\(Int($0.rounded()))%" } ?? " ")
                .font(.system(size: 18))
                .contentTransition(.numericText())
        }
        .padding(.top, 4)
    }
}
