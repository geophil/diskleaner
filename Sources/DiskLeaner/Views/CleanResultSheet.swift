import SwiftUI

struct CleanResultSheet: View {
    let result: CleanResult
    let onDismiss: () -> Void

    private var allFailed: Bool  { result.successCount == 0 && !result.failedItems.isEmpty }
    private var someFailed: Bool { !result.failedItems.isEmpty }

    var body: some View {
        VStack(spacing: 0) {

            // ── Header — always visible ──────────────────────────────
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(headerColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: headerIcon)
                        .font(.system(size: 22))
                        .foregroundStyle(headerColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(headerTitle).font(.title3.bold())
                    Text(headerSubtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(headerColor.opacity(0.06))

            Divider()

            // ── Scrollable body ──────────────────────────────────────
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Success row
                    if result.successCount > 0 {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text("\(result.successCount) item\(result.successCount == 1 ? "" : "s") cleaned — **\(Fmt.bytes(result.freedBytes))** freed")
                                .font(.callout)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        if someFailed { Divider() }
                    }

                    // Failed items
                    if someFailed {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("\(result.failedItems.count) item\(result.failedItems.count == 1 ? "" : "s") could not be removed")
                                    .font(.callout.bold())
                                    .foregroundStyle(.orange)
                            }

                            VStack(alignment: .leading, spacing: 5) {
                                ForEach(result.failedItems, id: \.self) { msg in
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.red)
                                            .padding(.top, 1)
                                        Text(firstLine(of: msg))
                                            .font(.system(size: 11))
                                            .foregroundStyle(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.08)))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)

                        Divider()

                        // Tips
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Common reasons & fixes")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            tipRow(icon: "lock.shield",
                                   text: "Full Disk Access not granted — System Settings › Privacy & Security › Full Disk Access › add DiskLeaner",
                                   action: { FullDiskAccess.openSystemSettings() })
                            tipRow(icon: "app.badge",
                                   text: "The app is currently running — quit it first, then scan and clean again")
                            tipRow(icon: "exclamationmark.lock",
                                   text: "System-protected file — use the admin-level categories (shown with 🔒 in the sidebar)")
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    }
                }
            }
            .frame(maxHeight: 280)   // cap height so Done is always on screen

            Divider()

            // ── Done button — always visible ─────────────────────────
            HStack {
                Spacer()
                Button("Done") { onDismiss() }
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
                    .tint(allFailed ? .orange : .accentColor)
            }
            .padding(16)
        }
        .frame(width: 480)
    }

    // MARK: Helpers

    /// Show only the first line of an error message — prevents rm -rf from
    /// dumping hundreds of "Operation not permitted" lines.
    private func firstLine(of message: String) -> String {
        let line = message.components(separatedBy: "\n").first ?? message
        return line.count > 160 ? String(line.prefix(160)) + "…" : line
    }

    @ViewBuilder
    private func tipRow(icon: String, text: String, action: (() -> Void)? = nil) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 14)
            if let action {
                Button(text, action: action)
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            } else {
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var headerColor: Color {
        allFailed ? .red : someFailed ? .orange : .green
    }
    private var headerIcon: String {
        allFailed ? "xmark.circle.fill" : someFailed ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
    }
    private var headerTitle: String {
        allFailed ? "Cleanup Failed" : someFailed ? "Partially Cleaned" : "Cleanup Complete"
    }
    private var headerSubtitle: String {
        if allFailed  { return "No items could be removed — see details below" }
        if someFailed { return "\(result.successCount) succeeded, \(result.failedItems.count) failed" }
        return "\(result.successCount) item\(result.successCount == 1 ? "" : "s") removed successfully"
    }
}
