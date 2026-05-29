import SwiftUI

struct ContentView: View {
    @EnvironmentObject var scanner: DiskScanner
    @State private var showGlobalConfirm = false
    @State private var deletePermanently = false

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $scanner.selectedCategoryID)
                .environmentObject(scanner)
        } detail: {
            DetailView(categoryID: scanner.selectedCategoryID)
                .environmentObject(scanner)
        }
        // Cleaning progress overlay — appears over the whole window
        .overlay {
            if scanner.isCleaning {
                CleaningProgressOverlay()
                    .environmentObject(scanner)
            }
        }
        .navigationTitle("DiskLeaner")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    Task { await scanner.scanAll() }
                } label: {
                    Label("Scan My Mac", systemImage: "doc.viewfinder")
                }
                .disabled(scanner.isScanning || scanner.isCleaning)
                .help("Scan your Mac for cleanable files")
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if scanner.isCleaning {
                    EmptyView()   // overlay handles cleaning feedback
                } else if scanner.isScanning {
                    ProgressView(value: scanner.scanProgress).frame(width: 80)
                    Text("Scanning…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if scanner.totalSelectedCount > 0 {
                    Text("\(Fmt.bytes(scanner.totalSelectedSize)) selected")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Button {
                        showGlobalConfirm = true
                    } label: {
                        Label("Clean \(scanner.totalSelectedCount) Items", systemImage: "trash")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
        // Global confirm sheet (across all categories)
        .sheet(isPresented: $showGlobalConfirm) {
            GlobalConfirmSheet(
                scanner: scanner,
                permanently: $deletePermanently,
                onConfirm: {
                    showGlobalConfirm = false
                    Task { await scanner.clean(permanently: deletePermanently) }
                },
                onCancel: { showGlobalConfirm = false }
            )
        }
        // Clean result sheet — replaces the old .alert so failures are unmissable
        .sheet(isPresented: Binding(
            get: { scanner.cleanResult != nil },
            set: { if !$0 { scanner.cleanResult = nil } }
        )) {
            if let result = scanner.cleanResult {
                CleanResultSheet(result: result) {
                    scanner.cleanResult = nil
                }
            }
        }
        .frame(minWidth: 820, minHeight: 560)
    }
}

// MARK: - Global Confirm Sheet (all categories)
struct GlobalConfirmSheet: View {
    @ObservedObject var scanner: DiskScanner
    @Binding var permanently: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private var allSelected: [CleanupItem] {
        scanner.categories.flatMap { $0.items.filter(\.isSelected) }
    }

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
                    Text("\(scanner.totalSelectedCount) items across \(scanner.categories.filter { $0.selectedCount > 0 }.count) categories")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            Divider()

            // Per-category breakdown
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(scanner.categories.filter { $0.selectedCount > 0 }) { cat in
                        HStack {
                            Image(systemName: cat.icon)
                                .frame(width: 16)
                                .foregroundStyle(.secondary)
                            Text(cat.title)
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(cat.selectedCount) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(Fmt.bytes(cat.selectedSize))
                                .font(.system(size: 11).monospacedDigit())
                                .frame(minWidth: 65, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 240)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total: \(Fmt.bytes(scanner.totalSelectedSize))")
                        .font(.headline)
                    if scanner.categories.filter({ $0.selectedCount > 0 && $0.requiresAdmin }).count > 0 {
                        Label("Some items require admin password", systemImage: "lock.shield.fill")
                            .font(.caption).foregroundStyle(.orange)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $permanently) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete Permanently")
                            .font(.system(size: 13, weight: .medium))
                        Text("Skip Trash — cannot be recovered")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
                if !permanently {
                    Label("Files will be moved to Trash (recoverable)", systemImage: "checkmark.shield")
                        .font(.caption).foregroundStyle(.green)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)

            Divider()

            HStack {
                Button("Cancel", role: .cancel, action: onCancel).keyboardShortcut(.escape)
                Spacer()
                Button(permanently ? "Delete Permanently" : "Move to Trash", role: .destructive, action: onConfirm)
                    .buttonStyle(.borderedProminent)
                    .tint(permanently ? .red : .accentColor)
                    .keyboardShortcut(.return)
            }
            .padding(16)
        }
        .frame(width: 540)
    }
}
