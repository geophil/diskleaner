import Foundation
import SwiftUI

// MARK: - Risk Level
enum RiskLevel: String {
    case safe, caution, risky

    var color: Color {
        switch self {
        case .safe:    return .green
        case .caution: return .orange
        case .risky:   return .red
        }
    }
    var label: String {
        switch self {
        case .safe:    return "Safe to clean"
        case .caution: return "Review before cleaning"
        case .risky:   return "Use with care"
        }
    }
    var icon: String {
        switch self {
        case .safe:    return "checkmark.shield.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .risky:   return "xmark.shield.fill"
        }
    }
}

// MARK: - Delete Strategy
enum DeleteStrategy: Sendable {
    case trash                      // FileManager.trashItem (default, recoverable)
    case permanent                  // FileManager.removeItem
    case shell(String)              // shell command, no admin needed
    case adminShell(String)         // shell command, admin password required
}

// MARK: - Cleanup Item
struct CleanupItem: Identifiable, Sendable {
    let id: UUID
    let url: URL?
    let displayName: String
    let detail: String?
    let size: Int64
    var isSelected: Bool
    let isDirectory: Bool
    let deleteStrategy: DeleteStrategy
    let requiresAdmin: Bool

    init(
        id: UUID = UUID(),
        url: URL? = nil,
        displayName: String,
        detail: String? = nil,
        size: Int64,
        isSelected: Bool = true,
        isDirectory: Bool = true,
        deleteStrategy: DeleteStrategy = .trash,
        requiresAdmin: Bool = false
    ) {
        self.id = id
        self.url = url
        self.displayName = displayName
        self.detail = detail
        self.size = size
        self.isSelected = isSelected
        self.isDirectory = isDirectory
        self.deleteStrategy = deleteStrategy
        self.requiresAdmin = requiresAdmin
    }
}

// MARK: - Category Group
enum CategoryGroup: String, CaseIterable {
    case system        = "System"
    case appleApps     = "Apple Apps"
    case communication = "Communication"
    case developer     = "Developer"
    case containers    = "Containers & VMs"
    case orphaned      = "Leftovers"
}

// MARK: - Category Type
enum CategoryType: String, CaseIterable, Sendable {
    // System – user level
    case userCaches, appLogs, trash, savedAppState, crashReports
    case spotlightMetadata, timeMachineSnapshots, quickLookCache
    // System – admin level
    case systemCaches, systemLogs, macOSUpdates, garagebandSounds
    // Apple Apps
    case browserCaches, appleMusic, podcastDownloads, mailCache
    case iosBackups, iosFirmware, coreMLCache
    // Communication
    case slackCache, zoomCache, discordCache, teamsCache
    // Developer
    case xcodeData, xcodeSimulators, xcodeArchives
    case npmCache, yarnCache, pipCache, homebrewCache
    case gradleCache, mavenCache, cargoCache, goCache
    case nodeModules, pythonVenvs, condaCache
    case jetbrainsCache, vsCodeCache, androidStudio
    case cocoaPodsCache, flutterCache, terraformCache
    case nvmVersions, rubyGems
    // Containers
    case dockerCache
    // Orphaned
    case orphanedContainers, orphanedAppSupport
}

// MARK: - Cleanup Category
struct CleanupCategory: Identifiable {
    let id: UUID
    let type: CategoryType
    let title: String
    let subtitle: String
    let icon: String
    let group: CategoryGroup
    let riskLevel: RiskLevel
    let requiresAdmin: Bool
    let warningNote: String?

    var items: [CleanupItem] = []
    var isScanned: Bool = false
    var isScanning: Bool = false
    var scanError: String? = nil

    var totalSize: Int64   { items.reduce(0) { $0 + $1.size } }
    var selectedSize: Int64 { items.filter(\.isSelected).reduce(0) { $0 + $1.size } }
    var selectedCount: Int  { items.filter(\.isSelected).count }

    init(
        id: UUID = UUID(),
        type: CategoryType,
        title: String,
        subtitle: String,
        icon: String,
        group: CategoryGroup,
        riskLevel: RiskLevel = .safe,
        requiresAdmin: Bool = false,
        warningNote: String? = nil
    ) {
        self.id = id; self.type = type; self.title = title
        self.subtitle = subtitle; self.icon = icon; self.group = group
        self.riskLevel = riskLevel; self.requiresAdmin = requiresAdmin
        self.warningNote = warningNote
    }
}

// MARK: - Disk Stats
struct DiskStats {
    let totalSpace: Int64
    let freeSpace: Int64

    var usedSpace: Int64 { totalSpace - freeSpace }
    var freeFraction: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(freeSpace) / Double(totalSpace)
    }
    var usedFraction: Double { 1.0 - freeFraction }

    static func current() -> DiskStats? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        guard
            let attrs = try? FileManager.default.attributesOfFileSystem(forPath: home.path),
            let total = attrs[.systemSize] as? Int64,
            let free  = attrs[.systemFreeSize] as? Int64
        else { return nil }
        return DiskStats(totalSpace: total, freeSpace: free)
    }
}

// MARK: - Clean Result
struct CleanResult {
    var freedBytes: Int64 = 0
    var successCount: Int = 0
    var failedItems: [String] = []
}

// MARK: - Clean Error
enum CleanError: LocalizedError {
    case shellFailed(String, Int32)
    case adminFailed(String)
    case noURL

    var errorDescription: String? {
        switch self {
        case .shellFailed(let cmd, let code): return "'\(cmd)' exited \(code)"
        case .adminFailed(let msg):           return "Admin error: \(msg)"
        case .noURL:                          return "No file path available"
        }
    }
}
