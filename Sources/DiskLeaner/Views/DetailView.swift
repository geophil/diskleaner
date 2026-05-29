import SwiftUI

struct DetailView: View {
    @EnvironmentObject var scanner: DiskScanner
    let categoryID: CleanupCategory.ID?

    @State private var showConfirm = false
    @State private var deletePermanently = false
    @State private var sortOrder = SortOption.size

    enum SortOption { case size, name }

    private var category: CleanupCategory? {
        guard let id = categoryID else { return nil }
        return scanner.categories.first { $0.id == id }
    }

    var body: some View {
        if let cat = category {
            VStack(spacing: 0) {
                // ── Header ──────────────────────────────────────────
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(riskColor(cat).opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: cat.icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(riskColor(cat))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(cat.title)
                                .font(.title2.bold())
                            if cat.requiresAdmin {
                                Label("Admin required", systemImage: "lock.shield.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Capsule().fill(Color.orange.opacity(0.15)))
                            }
                            riskBadge(cat)
                        }
                        Text(cat.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Size summary
                    if cat.isScanned {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(Fmt.bytes(cat.totalSize))
                                .font(.title3.bold().monospacedDigit())
                            Text("total found")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if cat.selectedCount > 0 {
                                Text("\(Fmt.bytes(cat.selectedSize)) selected")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))

                // ── Warning banner ────────────────────────────────
                if let note = cat.warningNote {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(riskColor(cat))
                        Text(note)
                            .font(.callout)
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(10)
                    .background(riskColor(cat).opacity(0.08))
                }

                Divider()

                // ── State: not scanned / scanning / empty / items ──
                if !cat.isScanned && !cat.isScanning {
                    emptyPlaceholder(
                        icon: "magnifyingglass",
                        title: "Not Scanned Yet",
                        message: "Click \u{201C}Scan My Mac\u{201D} to find cleanable files."
                    )
                } else if cat.isScanning {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Scanning…")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if cat.items.isEmpty {
                    emptyPlaceholder(
                        icon: "checkmark.circle",
                        title: "Nothing to Clean",
                        message: "No files found in this category on your Mac."
                    )
                } else {
                    itemList(cat)
                }
            }
            .sheet(isPresented: $showConfirm) {
                ConfirmSheet(
                    category: cat,
                    permanently: $deletePermanently,
                    onConfirm: {
                        showConfirm = false
                        Task { await scanner.clean(permanently: deletePermanently) }
                    },
                    onCancel: { showConfirm = false }
                )
            }
        } else {
            // Nothing selected
            emptyPlaceholder(
                icon: "sidebar.left",
                title: "Select a Category",
                message: "Choose a category from the sidebar, then click Scan to find files."
            )
        }
    }

    // MARK: - Item List

    @ViewBuilder
    private func itemList(_ cat: CleanupCategory) -> some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                // Select all / none
                Button("Select All") {
                    scanner.selectAll(in: cat.id, selected: true)
                }
                Button("Select None") {
                    scanner.selectAll(in: cat.id, selected: false)
                }
                .buttonStyle(.plain)

                Spacer()

                Picker("Sort", selection: $sortOrder) {
                    Text("Size").tag(SortOption.size)
                    Text("Name").tag(SortOption.name)
                }
                .pickerStyle(.segmented)
                .frame(width: 130)

                Button {
                    showConfirm = true
                } label: {
                    Label("Clean Selected", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(cat.selectedCount == 0 || scanner.isCleaning)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Items
            let sorted: [CleanupItem] = sortOrder == .size
                ? cat.items.sorted { $0.size > $1.size }
                : cat.items.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }

            List {
                ForEach(sorted) { item in
                    ItemRow(item: item) {
                        scanner.toggleItem(categoryID: cat.id, itemID: item.id)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func emptyPlaceholder(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func riskColor(_ cat: CleanupCategory) -> Color { cat.riskLevel.color }

    @ViewBuilder
    private func riskBadge(_ cat: CleanupCategory) -> some View {
        if cat.riskLevel != .safe {
            Label(cat.riskLevel.label, systemImage: cat.riskLevel.icon)
                .font(.caption)
                .foregroundStyle(riskColor(cat))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Capsule().fill(riskColor(cat).opacity(0.12)))
        }
    }
}

// MARK: - Item Row
struct ItemRow: View {
    let item: CleanupItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox
            Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 16))
                .foregroundStyle(item.isSelected ? Color.accentColor : Color.secondary)
                .onTapGesture { onToggle() }

            // Icon
            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .font(.system(size: 13))
                .foregroundStyle(item.isDirectory ? Color.yellow : Color.secondary)

            // Names
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                if let detail = item.detail {
                    Text(detail)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Admin badge
            if item.requiresAdmin {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
            }

            // Size
            if item.size > 0 {
                Text(Fmt.bytes(item.size))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(item.isSelected ? .primary : .secondary)
                    .frame(minWidth: 70, alignment: .trailing)
            } else {
                Text("—")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .frame(minWidth: 70, alignment: .trailing)
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
    }
}
