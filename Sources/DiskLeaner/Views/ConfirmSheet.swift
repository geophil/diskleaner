import SwiftUI

struct ConfirmSheet: View {
    let category: CleanupCategory
    @Binding var permanently: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(spacing: 12) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Confirm Cleanup")
                        .font(.title2.bold())
                    Text("Review what will be removed from \(category.title)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            // Items to be deleted
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(category.items.filter(\.isSelected)) { item in
                        HStack {
                            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                                .foregroundStyle(item.isDirectory ? .yellow : .secondary)
                                .font(.system(size: 12))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                if let detail = item.detail {
                                    Text(detail)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            Text(item.size > 0 ? Fmt.bytes(item.size) : "—")
                                .font(.system(size: 11).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 3)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 260)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Total summary
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(category.selectedCount) items · \(Fmt.bytes(category.selectedSize))")
                        .font(.headline)
                    if category.requiresAdmin {
                        Label("Requires admin password", systemImage: "lock.shield.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Delete mode toggle
            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $permanently) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete Permanently")
                            .font(.system(size: 13, weight: .medium))
                        Text("Skip Trash — files cannot be recovered")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)

                if !permanently {
                    Label("Files will be moved to Trash (recoverable)", systemImage: "checkmark.shield")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Buttons
            HStack {
                Button("Cancel", role: .cancel, action: onCancel)
                    .keyboardShortcut(.escape)
                Spacer()
                Button(permanently ? "Delete Permanently" : "Move to Trash", role: .destructive) {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(permanently ? .red : .accentColor)
                .keyboardShortcut(.return)
            }
            .padding(16)
        }
        .frame(width: 520)
    }
}
