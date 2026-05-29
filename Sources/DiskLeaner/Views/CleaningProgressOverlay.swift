import SwiftUI

/// Full-window overlay shown while a clean operation is in progress.
/// Prevents interaction with the app and shows live per-item progress.
struct CleaningProgressOverlay: View {
    @EnvironmentObject var scanner: DiskScanner
    @State private var pulsing = false

    var body: some View {
        ZStack {
            // Dim the content behind
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            // Progress card
            VStack(spacing: 20) {

                // Animated icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(pulsing ? 0.2 : 0.08))
                        .frame(width: 64, height: 64)
                        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                                   value: pulsing)
                    Image(systemName: "trash.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.accentColor)
                }
                .onAppear { pulsing = true }
                .onDisappear { pulsing = false }

                Text("Cleaning…")
                    .font(.title3.bold())

                // Progress bar
                VStack(spacing: 6) {
                    ProgressView(value: scanner.cleanProgress)
                        .progressViewStyle(.linear)
                        .tint(Color.accentColor)
                        .frame(width: 320)
                        .animation(.easeInOut(duration: 0.3), value: scanner.cleanProgress)

                    HStack {
                        // Current item name (truncated)
                        Text(scanner.cleaningItemName)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: 240, alignment: .leading)

                        Spacer()

                        // e.g. "4 / 12"
                        if scanner.cleanTotalCount > 0 {
                            Text("\(scanner.cleanDoneCount) / \(scanner.cleanTotalCount)")
                                .font(.system(size: 11).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 320)
                }

                // Percentage
                Text(String(format: "%.0f%%", scanner.cleanProgress * 100))
                    .font(.system(.title2, design: .rounded).bold().monospacedDigit())
                    .foregroundStyle(Color.accentColor)
                    .animation(.easeInOut(duration: 0.2), value: scanner.cleanProgress)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
            )
        }
        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
    }
}
