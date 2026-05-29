import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var scanner: DiskScanner
    @Binding var selection: CleanupCategory.ID?
    @AppStorage("fdaWarningDismissed") private var fdaWarningDismissed = false

    var body: some View {
        VStack(spacing: 0) {
            // Full Disk Access warning — shown once until dismissed
            if !scanner.hasFullDiskAccess && !fdaWarningDismissed {
                HStack(spacing: 6) {
                    Button {
                        FullDiskAccess.openSystemSettings()
                        fdaWarningDismissed = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Full Disk Access needed")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Tap to open System Settings")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.leading, 10)
                        .padding(.trailing, 4)
                        .padding(.vertical, 7)
                    }
                    .buttonStyle(.plain)

                    Button {
                        fdaWarningDismissed = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(5)
                            .background(Circle().fill(Color.primary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                }
                .background(Color.orange.opacity(0.1))
                Divider()
            }

            // Disk usage ring
            if let stats = scanner.diskStats {
                DiskRingView(stats: stats, pendingFree: scanner.totalSelectedSize)
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
            }

            Divider().padding(.vertical, 8)

            // Scan button + summary
            VStack(spacing: 4) {
                Button {
                    Task { await scanner.scanAll() }
                } label: {
                    Label(scanner.isScanning ? "Scanning…" : "Scan My Mac",
                          systemImage: scanner.isScanning ? "rays" : "doc.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(scanner.isScanning || scanner.isCleaning)

                if scanner.isScanning {
                    ProgressView(value: scanner.scanProgress)
                        .tint(.accentColor)
                }

                if scanner.totalSelectedCount > 0 {
                    Text("\(scanner.totalSelectedCount) items · \(Fmt.bytes(scanner.totalSelectedSize)) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider()

            // Category list grouped by section
            List(selection: $selection) {
                ForEach(CategoryGroup.allCases, id: \.self) { group in
                    let cats = scanner.categories.filter { $0.group == group }
                    if !cats.isEmpty {
                        Section(group.rawValue) {
                            ForEach(cats) { cat in
                                CategoryRow(category: cat)
                                    .tag(cat.id)
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 220, idealWidth: 240, maxWidth: 280)
    }
}

// MARK: - Category Row
struct CategoryRow: View {
    let category: CleanupCategory

    var body: some View {
        HStack(spacing: 8) {
            // Icon with risk-coloured background
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconBackground)
                    .frame(width: 28, height: 28)
                Image(systemName: category.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(iconForeground)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(category.title)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    if category.requiresAdmin {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                    }
                }

                if category.isScanning {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(height: 10)
                } else if category.isScanned {
                    if category.totalSize > 0 {
                        Text(Fmt.bytes(category.totalSize))
                            .font(.system(size: 10).monospacedDigit())
                            .foregroundStyle(.secondary)
                    } else {
                        Text(category.items.isEmpty ? "Nothing found" : "\(category.items.count) items")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Not scanned")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)

            // Selected count badge
            if category.isScanned && category.selectedCount > 0 {
                Text("\(category.selectedCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.accentColor))
            }
        }
        .padding(.vertical, 2)
    }

    private var iconBackground: Color {
        switch category.riskLevel {
        case .safe:    return .accentColor.opacity(0.15)
        case .caution: return .orange.opacity(0.15)
        case .risky:   return .red.opacity(0.15)
        }
    }

    private var iconForeground: Color {
        switch category.riskLevel {
        case .safe:    return .accentColor
        case .caution: return .orange
        case .risky:   return .red
        }
    }
}
