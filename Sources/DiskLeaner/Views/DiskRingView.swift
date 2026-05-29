import SwiftUI

struct DiskRingView: View {
    let stats: DiskStats
    var pendingFree: Int64 = 0

    private var usedFraction: Double { stats.usedFraction }
    private var pendingFraction: Double {
        guard stats.totalSpace > 0 else { return 0 }
        return min(Double(pendingFree) / Double(stats.totalSpace), stats.usedFraction)
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 18)

                // Used space arc
                Circle()
                    .trim(from: 0, to: usedFraction - pendingFraction)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: usedFraction)

                // Pending-to-free arc (shown in green)
                if pendingFraction > 0 {
                    Circle()
                        .trim(from: usedFraction - pendingFraction, to: usedFraction)
                        .stroke(Color.green.opacity(0.7),
                                style: StrokeStyle(lineWidth: 18, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.4), value: pendingFraction)
                }

                // Centre labels
                VStack(spacing: 2) {
                    Text(Fmt.bytes(stats.freeSpace))
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(.primary)
                    Text("available")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if pendingFree > 0 {
                        Text("+\(Fmt.bytes(pendingFree))")
                            .font(.caption2.bold())
                            .foregroundStyle(.green)
                    }
                }
            }
            .frame(width: 130, height: 130)

            // Legend
            VStack(spacing: 4) {
                legend(color: LinearGradient(colors: [.blue, .purple],
                                              startPoint: .leading, endPoint: .trailing),
                       label: "Used", value: stats.usedSpace)
                legend(color: LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.3)],
                                              startPoint: .leading, endPoint: .trailing),
                       label: "Free", value: stats.freeSpace)
                Text("Total: \(Fmt.bytes(stats.totalSpace))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func legend<G: ShapeStyle>(color: G, label: String, value: Int64) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(Fmt.bytes(value))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: 140)
    }
}
