import Foundation
import SwiftUI

// MARK: - Category Definitions
// One canonical list of all categories, their metadata, and default state.
enum CategoryDefinitions {
    static func all() -> [CleanupCategory] {
        [
            // ── System (user-level) ───────────────────────────────
            cat(.userCaches, "User Caches", "~/Library/Caches — app cache files",
                icon: "internaldrive", group: .system),
            cat(.appLogs, "App Logs", "~/Library/Logs — application log files",
                icon: "doc.text", group: .system),
            cat(.trash, "Trash", "Files waiting in the Trash",
                icon: "trash", group: .system),
            cat(.savedAppState, "Saved App State", "App resume data for window restoration",
                icon: "arrow.counterclockwise", group: .system),
            cat(.crashReports, "Crash Reports", "Diagnostic crash & hang reports",
                icon: "exclamationmark.octagon", group: .system),
            cat(.spotlightMetadata, "Spotlight Metadata", "Index cache — known to balloon on Intel Macs",
                icon: "magnifyingglass", group: .system, risk: .caution,
                note: "Spotlight will rebuild its index after deletion. Takes a few minutes."),
            cat(.timeMachineSnapshots, "Time Machine Snapshots", "Local APFS snapshots invisible in Finder",
                icon: "clock.arrow.circlepath", group: .system,
                note: "Use tmutil to remove safely. Size shown as 0 because APFS snapshots share blocks."),
            cat(.quickLookCache, "Quick Look Cache", "Thumbnail cache — rebuilt on demand",
                icon: "eye", group: .system),

            // ── System (admin-level) ──────────────────────────────
            cat(.systemCaches, "System Caches", "/Library/Caches — machine-level app caches",
                icon: "server.rack", group: .system, admin: true),
            cat(.systemLogs, "System Logs", "/Library/Logs and /var/log",
                icon: "list.bullet.rectangle", group: .system, admin: true),
            cat(.macOSUpdates, "macOS Update Packages", "Installer packages left after updating",
                icon: "arrow.down.circle", group: .system, admin: true),
            cat(.garagebandSounds, "GarageBand / Logic Sounds", "Sound libraries & Apple Loops",
                icon: "music.note", group: .system, risk: .caution, admin: true,
                note: "Re-downloadable from GarageBand / Logic preferences."),

            // ── Apple Apps ────────────────────────────────────────
            cat(.browserCaches, "Browser Caches", "Chrome, Safari, Firefox, Brave, Arc, Edge…",
                icon: "globe", group: .appleApps),
            cat(.appleMusic, "Apple Music Cache", "Streaming & subscription play cache",
                icon: "music.note.list", group: .appleApps),
            cat(.podcastDownloads, "Podcast Downloads", "Downloaded podcast episodes",
                icon: "mic", group: .appleApps),
            cat(.mailCache, "Mail Cache & Attachments", "Mail app cache and downloaded attachments",
                icon: "envelope", group: .appleApps),
            cat(.iosBackups, "iOS Device Backups", "iPhone/iPad backups stored on this Mac",
                icon: "iphone", group: .appleApps, risk: .caution,
                note: "These are your device backups. Deleting them removes the only local copy. Make sure iCloud backup is on first."),
            cat(.iosFirmware, "iOS Firmware (IPSW)", "Downloaded iPhone/iPad firmware files",
                icon: "cpu", group: .appleApps),
            cat(.coreMLCache, "CoreML Model Cache", "Compiled AI model cache — can reach 200+ GB",
                icon: "brain", group: .appleApps),

            // ── Communication ─────────────────────────────────────
            cat(.slackCache, "Slack Cache", "Slack media, GPU, and code caches",
                icon: "message", group: .communication),
            cat(.zoomCache, "Zoom Cache", "Zoom data, logs, and system cache",
                icon: "video", group: .communication),
            cat(.discordCache, "Discord Cache", "Discord media and GPU cache",
                icon: "bubble.left.and.bubble.right", group: .communication),
            cat(.teamsCache, "Microsoft Teams Cache", "Teams data and containers",
                icon: "person.3", group: .communication),

            // ── Developer ─────────────────────────────────────────
            cat(.xcodeData, "Xcode Build Data", "DerivedData, DeviceSupport — usually huge",
                icon: "hammer", group: .developer),
            cat(.xcodeSimulators, "Xcode Simulators", "Simulator runtimes and unused devices",
                icon: "iphone.gen1", group: .developer),
            cat(.xcodeArchives, "Xcode Archives", "App archives — needed for crash symbolication",
                icon: "archivebox", group: .developer, risk: .caution,
                note: "Archives are needed to symbolicate crash logs from previously distributed builds."),
            cat(.npmCache, "npm Cache", "~/.npm/_cacache",
                icon: "shippingbox", group: .developer),
            cat(.yarnCache, "Yarn Cache", "Yarn package download cache",
                icon: "shippingbox", group: .developer),
            cat(.pipCache, "pip Cache", "Python pip download cache",
                icon: "shippingbox", group: .developer),
            cat(.homebrewCache, "Homebrew Cache", "Downloaded Homebrew formula bottles",
                icon: "shippingbox", group: .developer),
            cat(.gradleCache, "Gradle Cache", "Gradle dependencies and wrapper distributions",
                icon: "shippingbox", group: .developer),
            cat(.mavenCache, "Maven Repository", "~/.m2/repository — all downloaded JARs",
                icon: "shippingbox", group: .developer),
            cat(.cargoCache, "Cargo Cache", "Rust package registry and git cache",
                icon: "shippingbox", group: .developer),
            cat(.goCache, "Go Cache", "Go module and build cache",
                icon: "shippingbox", group: .developer),
            cat(.nodeModules, "node_modules", "All node_modules directories in your home folder",
                icon: "folder.badge.gearshape", group: .developer, risk: .caution,
                note: "Deselected by default — review each project. Run npm/yarn install to restore."),
            cat(.pythonVenvs, "Python Virtualenvs", ".venv / venv directories across projects",
                icon: "terminal", group: .developer, risk: .caution,
                note: "Deselected by default — check each project. Re-create with python -m venv."),
            cat(.condaCache, "Conda Cache", "Anaconda / Miniconda package cache",
                icon: "shippingbox", group: .developer),
            cat(.jetbrainsCache, "JetBrains IDE Caches", "IntelliJ, PyCharm, WebStorm, GoLand…",
                icon: "curlybraces", group: .developer),
            cat(.vsCodeCache, "VS Code / Cursor / Zed", "Editor caches and workspace storage",
                icon: "chevron.left.forwardslash.chevron.right", group: .developer),
            cat(.androidStudio, "Android Studio", "AVD emulators and Android SDK",
                icon: "candybarphone", group: .developer, risk: .caution,
                note: "Remove only AVDs and SDK versions you no longer need."),
            cat(.cocoaPodsCache, "CocoaPods Cache", "Pod download cache and spec repos",
                icon: "shippingbox", group: .developer),
            cat(.flutterCache, "Flutter / Dart Cache", "Pub package cache and DevTools",
                icon: "shippingbox", group: .developer),
            cat(.terraformCache, "Terraform Cache", "Provider plugin cache",
                icon: "shippingbox", group: .developer),
            cat(.nvmVersions, "nvm Node Versions", "Old Node.js versions via nvm",
                icon: "number", group: .developer, risk: .caution,
                note: "Only remove Node versions you no longer use. Run 'nvm current' to check active version."),
            cat(.rubyGems, "Ruby Gems", "~/.gem — user-installed Ruby gems",
                icon: "shippingbox", group: .developer),

            // ── Containers & VMs ──────────────────────────────────
            cat(.dockerCache, "Docker / OrbStack / Colima", "Container images, volumes, and VM data",
                icon: "shippingbox.fill", group: .containers, risk: .caution,
                note: "Docker uses 'docker system prune' — not a direct file delete. Deselected by default."),

            // ── Leftovers ─────────────────────────────────────────
            cat(.orphanedContainers, "Orphaned App Containers", "~/Library/Containers for uninstalled apps",
                icon: "xmark.seal", group: .orphaned, risk: .caution,
                note: "Matched against installed apps. Deselected by default — verify before cleaning."),
            cat(.orphanedAppSupport, "Orphaned App Support", "~/Library/Application Support for uninstalled apps",
                icon: "xmark.seal", group: .orphaned, risk: .caution,
                note: "Large folders not matching any installed app. Deselected by default."),
        ]
    }

    private static func cat(
        _ type: CategoryType, _ title: String, _ subtitle: String,
        icon: String, group: CategoryGroup,
        risk: RiskLevel = .safe, admin: Bool = false, note: String? = nil
    ) -> CleanupCategory {
        CleanupCategory(type: type, title: title, subtitle: subtitle,
                        icon: icon, group: group,
                        riskLevel: risk, requiresAdmin: admin, warningNote: note)
    }
}

// MARK: - Full Disk Access helper
enum FullDiskAccess {
    /// Returns true if the app can read the TCC database — a reliable FDA indicator.
    static var isGranted: Bool {
        let tcc = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/com.apple.TCC/TCC.db")
        return FileManager.default.isReadableFile(atPath: tcc.path)
    }

    static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
}

// MARK: - DiskScanner
@MainActor
final class DiskScanner: ObservableObject {
    @Published var categories: [CleanupCategory] = CategoryDefinitions.all()
    @Published var diskStats: DiskStats? = DiskStats.current()
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var hasFullDiskAccess: Bool = FullDiskAccess.isGranted

    // Cleaning progress
    @Published var isCleaning = false
    @Published var cleanProgress: Double = 0      // 0.0 → 1.0
    @Published var cleanDoneCount: Int = 0
    @Published var cleanTotalCount: Int = 0
    @Published var cleaningItemName: String = ""  // currently-being-deleted item

    @Published var cleanResult: CleanResult?
    @Published var selectedCategoryID: CleanupCategory.ID?

    var totalSelectedSize: Int64 { categories.reduce(0) { $0 + $1.selectedSize } }
    var totalSelectedCount: Int  { categories.reduce(0) { $0 + $1.selectedCount } }

    var selectedCategory: CleanupCategory? {
        guard let id = selectedCategoryID else { return nil }
        return categories.first { $0.id == id }
    }

    // MARK: Subscript helper
    private func index(of id: CleanupCategory.ID) -> Int? {
        categories.firstIndex { $0.id == id }
    }

    // MARK: - Toggle helpers
    func toggleItem(categoryID: CleanupCategory.ID, itemID: CleanupItem.ID) {
        guard let ci = index(of: categoryID),
              let ii = categories[ci].items.firstIndex(where: { $0.id == itemID })
        else { return }
        categories[ci].items[ii].isSelected.toggle()
    }

    func selectAll(in categoryID: CleanupCategory.ID, selected: Bool) {
        guard let ci = index(of: categoryID) else { return }
        for ii in categories[ci].items.indices {
            categories[ci].items[ii].isSelected = selected
        }
    }

    // MARK: - Scan
    func scanAll() async {
        isScanning = true
        scanProgress = 0
        hasFullDiskAccess = FullDiskAccess.isGranted
        diskStats = DiskStats.current()

        for i in categories.indices {
            categories[i].isScanning = true
            categories[i].isScanned  = false
            categories[i].items      = []
        }

        let types = categories.map { (id: $0.id, type: $0.type) }
        let total = Double(types.count)
        var completed = 0

        await withTaskGroup(of: (CleanupCategory.ID, [CleanupItem]).self) { group in
            for entry in types {
                group.addTask {
                    let items = await CategoryScanner.scan(entry.type)
                    return (entry.id, items)
                }
            }
            for await (catID, items) in group {
                if let ci = self.index(of: catID) {
                    self.categories[ci].items     = items
                    self.categories[ci].isScanned = true
                    self.categories[ci].isScanning = false
                }
                completed += 1
                scanProgress = Double(completed) / total
            }
        }

        isScanning = false
        diskStats = DiskStats.current()
    }

    // MARK: - Clean
    func clean(permanently: Bool = false) async {
        cleanResult = nil

        // Build (categoryIndex, item) pairs so we can remove each item
        // from its category immediately after successful deletion.
        typealias IndexedItem = (categoryIndex: Int, item: CleanupItem)

        let normalPairs: [IndexedItem] = categories.enumerated().flatMap { ci, cat in
            cat.items.filter { $0.isSelected && !$0.requiresAdmin }.map { (ci, $0) }
        }
        let adminPairs: [IndexedItem] = categories.enumerated().flatMap { ci, cat in
            cat.items.filter { $0.isSelected && $0.requiresAdmin }.map { (ci, $0) }
        }

        let totalSteps = normalPairs.count + (adminPairs.isEmpty ? 0 : 1)

        isCleaning       = true
        cleanProgress    = 0
        cleanDoneCount   = 0
        cleanTotalCount  = totalSteps
        cleaningItemName = ""

        var result = CleanResult()

        // ── Normal items ─────────────────────────────────────────
        for (ci, item) in normalPairs {
            cleaningItemName = item.displayName
            do {
                let freed = try await doClean(item, permanently: permanently)
                result.freedBytes   += freed
                result.successCount += 1

                // ✅ Remove immediately — sidebar size & count update live
                categories[ci].items.removeAll { $0.id == item.id }

                // ✅ Refresh free-space ring after every deletion
                diskStats = DiskStats.current()
            } catch {
                result.failedItems.append("\(item.displayName): \(error.localizedDescription)")
            }
            cleanDoneCount += 1
            cleanProgress   = totalSteps > 0 ? Double(cleanDoneCount) / Double(totalSteps) : 1
        }

        // ── Admin items (one password prompt for the whole batch) ─
        if !adminPairs.isEmpty {
            cleaningItemName = "Admin cleanup (\(adminPairs.count) item\(adminPairs.count == 1 ? "" : "s"))…"
            let cmds  = adminPairs.map(\.item).compactMap { adminCommand(for: $0, permanently: permanently) }
            let batch = cmds.joined(separator: "; ")
            do {
                try await runAdminShell(batch)
                for (ci, item) in adminPairs {
                    result.freedBytes   += item.size
                    result.successCount += 1
                    categories[ci].items.removeAll { $0.id == item.id }
                }
                diskStats = DiskStats.current()
            } catch {
                for (_, item) in adminPairs {
                    result.failedItems.append("\(item.displayName): \(error.localizedDescription)")
                }
            }
            cleanDoneCount += 1
            cleanProgress   = 1
        }

        cleanResult      = result
        isCleaning       = false
        cleaningItemName = ""
        diskStats        = DiskStats.current()

        // No automatic rescan here. Items are already removed from the list
        // as they're deleted. An auto-rescan causes confusion because running
        // apps (Teams, Slack, Chrome…) recreate their caches within seconds,
        // making successfully-deleted items appear to come back.
        // The user can press "Scan My Mac" at any time to get fresh numbers.
    }

    // MARK: - Internals

    private func adminCommand(for item: CleanupItem, permanently: Bool) -> String? {
        switch item.deleteStrategy {
        case .adminShell(let cmd):
            if let url = item.url {
                return "\(cmd) \"\(url.path)\""
            }
            return cmd
        case .trash, .permanent:
            if let url = item.url {
                return "rm -rf \"\(url.path)\""
            }
            return nil
        default:
            return nil
        }
    }

    private func doClean(_ item: CleanupItem, permanently: Bool) async throws -> Int64 {
        let size = item.size
        switch item.deleteStrategy {

        case .trash:
            guard let url = item.url else { throw CleanError.noURL }
            // Run on a background thread — trashItem/removeItem can be slow for large dirs
            try await Task.detached(priority: .userInitiated) {
                if permanently {
                    try FileManager.default.removeItem(at: url)
                } else {
                    try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                }
            }.value

        case .permanent:
            guard let url = item.url else { throw CleanError.noURL }
            try await Task.detached(priority: .userInitiated) {
                try FileManager.default.removeItem(at: url)
            }.value

        case .shell(let cmd):
            try await runShell(cmd)

        case .adminShell(let cmd):
            let full = item.url.map { "\(cmd) \"\($0.path)\"" } ?? cmd
            try await runAdminShell(full)
        }
        return size
    }

    // MARK: Shell runners

    func runShell(_ command: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
                proc.arguments = ["-c", command]
                do {
                    try proc.run()
                    proc.waitUntilExit()
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func runAdminShell(_ command: String) async throws {
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(escaped)\" with administrator privileges"

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var errDict: NSDictionary?
                let appleScript = NSAppleScript(source: script)
                _ = appleScript?.executeAndReturnError(&errDict)
                if let err = errDict {
                    let msg = (err[NSAppleScript.errorMessage] as? String) ?? "Admin command failed"
                    // Error code -128 = user cancelled
                    if let code = err[NSAppleScript.errorNumber] as? Int, code == -128 {
                        cont.resume()   // treat cancel as no-op
                    } else {
                        cont.resume(throwing: CleanError.adminFailed(msg))
                    }
                } else {
                    cont.resume()
                }
            }
        }
    }
}
