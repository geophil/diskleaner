import Foundation

// MARK: - CategoryScanner
// All scan functions are pure file-system reads — safe to call from background tasks.
struct CategoryScanner {

    static let fm   = FileManager.default
    static var home: URL { fm.homeDirectoryForCurrentUser }

    // ──────────────────────────────────────────────────────────────
    // MARK: Dispatch
    // ──────────────────────────────────────────────────────────────

    static func scan(_ type: CategoryType) async -> [CleanupItem] {
        switch type {
        // System – user
        case .userCaches:          return scanUserCaches()
        case .appLogs:             return scanAppLogs()
        case .trash:               return scanTrash()
        case .savedAppState:       return scanSavedAppState()
        case .crashReports:        return scanCrashReports()
        case .spotlightMetadata:   return scanSpotlightMetadata()
        case .timeMachineSnapshots:return await scanTimeMachineSnapshots()
        case .quickLookCache:      return scanQuickLookCache()
        // System – admin
        case .systemCaches:        return scanSystemCaches()
        case .systemLogs:          return scanSystemLogs()
        case .macOSUpdates:        return scanMacOSUpdates()
        case .garagebandSounds:    return scanGarageBand()
        // Apple Apps
        case .browserCaches:       return scanBrowserCaches()
        case .appleMusic:          return scanAppleMusic()
        case .podcastDownloads:    return scanPodcasts()
        case .mailCache:           return scanMail()
        case .iosBackups:          return scanIOSBackups()
        case .iosFirmware:         return scanIOSFirmware()
        case .coreMLCache:         return scanCoreML()
        // Communication
        case .slackCache:          return scanSlack()
        case .zoomCache:           return scanZoom()
        case .discordCache:        return scanDiscord()
        case .teamsCache:          return scanTeams()
        // Developer
        case .xcodeData:           return scanXcodeData()
        case .xcodeSimulators:     return await scanXcodeSimulators()
        case .xcodeArchives:       return scanXcodeArchives()
        case .npmCache:            return scanNpm()
        case .yarnCache:           return scanYarn()
        case .pipCache:            return scanPip()
        case .homebrewCache:       return scanHomebrew()
        case .gradleCache:         return scanGradle()
        case .mavenCache:          return scanMaven()
        case .cargoCache:          return scanCargo()
        case .goCache:             return scanGo()
        case .nodeModules:         return scanNodeModules()
        case .pythonVenvs:         return scanPythonVenvs()
        case .condaCache:          return scanConda()
        case .jetbrainsCache:      return scanJetBrains()
        case .vsCodeCache:         return scanVSCode()
        case .androidStudio:       return scanAndroidStudio()
        case .cocoaPodsCache:      return scanCocoaPods()
        case .flutterCache:        return scanFlutter()
        case .terraformCache:      return scanTerraform()
        case .nvmVersions:         return scanNvm()
        case .rubyGems:            return scanRubyGems()
        // Containers
        case .dockerCache:         return scanDocker()
        // Orphaned
        case .orphanedContainers:  return scanOrphanedContainers()
        case .orphanedAppSupport:  return scanOrphanedAppSupport()
        }
    }

    // ──────────────────────────────────────────────────────────────
    // MARK: Helpers
    // ──────────────────────────────────────────────────────────────

    static func dirSize(_ url: URL) -> Int64 {
        guard fm.fileExists(atPath: url.path) else { return 0 }
        var size: Int64 = 0
        let keys: Set<URLResourceKey> = [.fileSizeKey, .isRegularFileKey]
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: []
        ) else { return 0 }
        for case let fileURL as URL in enumerator {
            guard
                let vals = try? fileURL.resourceValues(forKeys: keys),
                vals.isRegularFile == true
            else { continue }
            size += Int64(vals.fileSize ?? 0)
        }
        return size
    }

    /// Scan immediate children of `parent` as individual cleanup items.
    static func subdirs(
        of parent: URL,
        defaultSelected: Bool = true,
        requiresAdmin: Bool = false,
        deleteStrategy: DeleteStrategy = .trash,
        minSize: Int64 = 1024
    ) -> [CleanupItem] {
        guard fm.fileExists(atPath: parent.path) else { return [] }
        let contents = (try? fm.contentsOfDirectory(
            at: parent,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: []
        )) ?? []
        return contents.compactMap { url -> CleanupItem? in
            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            let size  = isDir
                ? dirSize(url)
                : Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
            guard size >= minSize else { return nil }
            return CleanupItem(
                url: url,
                displayName: url.lastPathComponent,
                detail: url.path,
                size: size,
                isSelected: defaultSelected,
                isDirectory: isDir,
                deleteStrategy: deleteStrategy,
                requiresAdmin: requiresAdmin
            )
        }.sorted { $0.size > $1.size }
    }

    /// Single-item helper — returns nil if path doesn't exist or is empty.
    static func singleItem(
        _ path: String,
        displayName: String? = nil,
        detail: String? = nil,
        defaultSelected: Bool = true,
        requiresAdmin: Bool = false,
        deleteStrategy: DeleteStrategy = .trash
    ) -> CleanupItem? {
        let url = URL(fileURLWithPath: path)
        guard fm.fileExists(atPath: path) else { return nil }
        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        let size  = isDir
            ? dirSize(url)
            : Int64((try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
        guard size > 0 else { return nil }
        return CleanupItem(
            url: url,
            displayName: displayName ?? url.lastPathComponent,
            detail: detail ?? path,
            size: size,
            isSelected: defaultSelected,
            isDirectory: isDir,
            deleteStrategy: deleteStrategy,
            requiresAdmin: requiresAdmin
        )
    }

    /// Run a shell command and return stdout.
    static func shell(_ cmd: String) -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-c", cmd]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError  = Pipe()
        try? proc.run()
        proc.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    static func p(_ components: String...) -> String {
        ([home.path] + components).joined(separator: "/")
    }

    // ──────────────────────────────────────────────────────────────
    // MARK: System – user level
    // ──────────────────────────────────────────────────────────────

    static func scanUserCaches() -> [CleanupItem] {
        subdirs(of: URL(fileURLWithPath: p("Library", "Caches")))
    }

    static func scanAppLogs() -> [CleanupItem] {
        subdirs(of: URL(fileURLWithPath: p("Library", "Logs")), minSize: 512)
    }

    static func scanTrash() -> [CleanupItem] {
        let url = URL(fileURLWithPath: p(".Trash"))
        let size = dirSize(url)
        guard size > 0 else { return [] }
        return [CleanupItem(
            url: url, displayName: "Trash", detail: "~/.Trash",
            size: size, isSelected: true, isDirectory: true,
            deleteStrategy: .permanent
        )]
    }

    static func scanSavedAppState() -> [CleanupItem] {
        subdirs(of: URL(fileURLWithPath: p("Library", "Saved Application State")), minSize: 512)
    }

    static func scanCrashReports() -> [CleanupItem] {
        let paths = [
            p("Library", "Logs", "DiagnosticReports"),
            p("Library", "Application Support", "CrashReporter")
        ]
        return paths.flatMap { path -> [CleanupItem] in
            let url = URL(fileURLWithPath: path)
            guard fm.fileExists(atPath: path),
                  let files = try? fm.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: [.fileSizeKey],
                    options: []
                  )
            else { return [] }
            return files.compactMap { f -> CleanupItem? in
                let size = Int64((try? f.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
                guard size > 0 else { return nil }
                return CleanupItem(
                    url: f, displayName: f.lastPathComponent,
                    detail: f.path, size: size,
                    isSelected: true, isDirectory: false,
                    deleteStrategy: .permanent
                )
            }
        }.sorted { $0.size > $1.size }
    }

    static func scanSpotlightMetadata() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("Library", "Metadata", "CoreSpotlight"),
             "Spotlight index — will rebuild automatically"),
            (p("Library", "Metadata", "SpotlightKnowledgeEvents"),
             "Spotlight knowledge events (known macOS bloat bug)")
        ]
        return paths.compactMap { (path, note) in
            singleItem(path, displayName: URL(fileURLWithPath: path).lastPathComponent,
                       detail: note, defaultSelected: true, deleteStrategy: .trash)
        }
    }

    static func scanTimeMachineSnapshots() async -> [CleanupItem] {
        let output = shell("tmutil listlocalsnapshots / 2>/dev/null")
        let lines = output.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return lines.map { snapshot in
            // snapshot looks like: com.apple.TimeMachine.2024-01-15-123456
            let date = snapshot.replacingOccurrences(of: "com.apple.TimeMachine.", with: "")
            return CleanupItem(
                url: nil,
                displayName: snapshot,
                detail: "Local APFS snapshot — use tmutil to remove safely",
                size: 0,   // APFS snapshots share blocks; exact size not easily available
                isSelected: true,
                isDirectory: false,
                deleteStrategy: .shell("tmutil deletelocalsnapshots \(date)")
            )
        }
    }

    static func scanQuickLookCache() -> [CleanupItem] {
        // Quick Look cache path is hashed per user; use qlmanage to clear it properly.
        return [CleanupItem(
            url: nil,
            displayName: "Quick Look Thumbnail Cache",
            detail: "Cleared via: qlmanage -r cache",
            size: 0,
            isSelected: true,
            isDirectory: false,
            deleteStrategy: .shell("qlmanage -r cache 2>/dev/null; qlmanage -r diskcache 2>/dev/null")
        )]
    }

    // ──────────────────────────────────────────────────────────────
    // MARK: System – admin level
    // ──────────────────────────────────────────────────────────────

    static func scanSystemCaches() -> [CleanupItem] {
        subdirs(of: URL(fileURLWithPath: "/Library/Caches"),
                requiresAdmin: true,
                deleteStrategy: .adminShell("rm -rf"),
                minSize: 1024)
    }

    static func scanSystemLogs() -> [CleanupItem] {
        let paths = ["/Library/Logs", "/var/log"]
        return paths.flatMap { path -> [CleanupItem] in
            subdirs(of: URL(fileURLWithPath: path),
                    requiresAdmin: true,
                    deleteStrategy: .adminShell("rm -rf"),
                    minSize: 512)
        }
    }

    static func scanMacOSUpdates() -> [CleanupItem] {
        [singleItem("/Library/Updates",
                    displayName: "macOS Update Packages",
                    detail: "Downloaded macOS installer packages — safe to remove after updating",
                    requiresAdmin: true,
                    deleteStrategy: .adminShell("rm -rf \"/Library/Updates\""))
        ].compactMap { $0 }
    }

    static func scanGarageBand() -> [CleanupItem] {
        let paths: [(String, String)] = [
            ("/Library/Application Support/GarageBand",    "GarageBand instrument library"),
            ("/Library/Application Support/Logic",         "Logic Pro sound library"),
            ("/Library/Audio/Apple Loops",                  "Apple Loops audio samples"),
            ("/Library/Application Support/GarageBand/Instrument Library/Sampler/Sampler Files",
             "GarageBand sampler files")
        ]
        return paths.compactMap { (path, name) in
            singleItem(path, displayName: name, detail: path,
                       requiresAdmin: true,
                       deleteStrategy: .adminShell("rm -rf \"\(path)\""))
        }
    }

    // ──────────────────────────────────────────────────────────────
    // MARK: Apple Apps
    // ──────────────────────────────────────────────────────────────

    static func scanBrowserCaches() -> [CleanupItem] {
        let browsers: [(String, String)] = [
            // (display name, relative path from ~/Library/...)
            ("Google Chrome",   p("Library", "Application Support", "Google", "Chrome", "Default", "Cache")),
            ("Google Chrome (GPU)", p("Library", "Application Support", "Google", "Chrome", "Default", "GPUCache")),
            ("Safari",          p("Library", "Caches", "com.apple.Safari")),
            ("Firefox",         p("Library", "Application Support", "Firefox", "Profiles")),
            ("Brave Browser",   p("Library", "Application Support", "BraveSoftware", "Brave-Browser", "Default", "Cache")),
            ("Arc",             p("Library", "Application Support", "Arc", "User Data", "Default", "Cache")),
            ("Microsoft Edge",  p("Library", "Application Support", "Microsoft Edge", "Default", "Cache")),
            ("Opera",           p("Library", "Application Support", "com.operasoftware.Opera", "Default", "Cache")),
            ("Vivaldi",         p("Library", "Application Support", "Vivaldi", "Default", "Cache")),
        ]
        var items: [CleanupItem] = []
        for (name, path) in browsers {
            if name == "Firefox" {
                // Firefox profiles have sub-dirs with cache2 inside
                let profilesURL = URL(fileURLWithPath: path)
                if let profiles = try? fm.contentsOfDirectory(at: profilesURL, includingPropertiesForKeys: nil, options: []) {
                    for profile in profiles {
                        let cache = profile.appendingPathComponent("cache2")
                        if let item = singleItem(cache.path, displayName: "Firefox (\(profile.lastPathComponent))",
                                                 detail: cache.path) {
                            items.append(item)
                        }
                    }
                }
            } else if let item = singleItem(path, displayName: name, detail: path) {
                items.append(item)
            }
        }
        return items.sorted { $0.size > $1.size }
    }

    static func scanAppleMusic() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("Library", "Caches", "com.apple.Music"),
             "Apple Music app cache"),
            (p("Library", "Caches", "com.apple.Music", "SubscriptionPlayCache"),
             "Apple Music streaming play cache")
        ]
        return paths.compactMap { singleItem($0.0, displayName: "Apple Music Cache", detail: $0.1) }
    }

    static func scanPodcasts() -> [CleanupItem] {
        let base = p("Library", "Group Containers", "243LU875E5.groups.com.apple.podcasts", "Library", "Cache")
        return [singleItem(base, displayName: "Podcast Downloads & Cache",
                           detail: "Downloaded podcast episodes")].compactMap { $0 }
    }

    static func scanMail() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("Library", "Containers", "com.apple.mail", "Data", "Library", "Caches"),
             "Mail app cache"),
            (p("Library", "Containers", "com.apple.mail", "Data", "Library", "Mail Downloads"),
             "Mail downloaded attachments"),
            (p("Library", "Mail Downloads"),
             "Legacy mail attachments")
        ]
        return paths.compactMap { singleItem($0.0, displayName: "Mail — \($0.1)", detail: $0.0) }
    }

    static func scanIOSBackups() -> [CleanupItem] {
        subdirs(
            of: URL(fileURLWithPath: p("Library", "Application Support", "MobileSync", "Backup")),
            defaultSelected: false  // Caution: deselect by default
        )
    }

    static func scanIOSFirmware() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("Library", "iTunes", "iPhone Software Updates"), "iPhone firmware (IPSW) files"),
            (p("Library", "iTunes", "iPad Software Updates"),   "iPad firmware (IPSW) files"),
            (p("Library", "iTunes", "iPod Software Updates"),   "iPod firmware (IPSW) files"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: $0.1, detail: $0.0) }
    }

    static func scanCoreML() -> [CleanupItem] {
        [singleItem(
            p("Library", "Application Support", "coreMLCache"),
            displayName: "CoreML Model Cache",
            detail: "Compiled AI/ML models (Topaz, DaVinci, etc.) — apps rebuild on next launch"
        )].compactMap { $0 }
    }

    // ──────────────────────────────────────────────────────────────
    // MARK: Communication
    // ──────────────────────────────────────────────────────────────

    static func scanSlack() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("Library", "Application Support", "Slack", "Cache"),      "Slack cache (direct)"),
            (p("Library", "Application Support", "Slack", "Code Cache"), "Slack code cache"),
            (p("Library", "Application Support", "Slack", "GPUCache"),   "Slack GPU cache"),
            (p("Library", "Containers", "com.tinyspeck.slackmacgap", "Data", "Library", "Application Support", "Slack", "Cache"),
             "Slack cache (App Store)"),
            (p("Library", "Caches", "com.tinyspeck.slackmacgap"),        "Slack system cache"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: "Slack — \($0.1)", detail: $0.0) }
            .sorted { $0.size > $1.size }
    }

    static func scanZoom() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("Library", "Application Support", "zoom.us"), "Zoom data & cache"),
            (p("Library", "Caches", "us.zoom.xos"),          "Zoom system cache"),
            (p("Library", "Logs", "zoom.us"),                "Zoom logs"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: "Zoom — \($0.1)", detail: $0.0) }
            .sorted { $0.size > $1.size }
    }

    static func scanDiscord() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("Library", "Application Support", "discord", "Cache"),     "Discord media cache"),
            (p("Library", "Application Support", "discord", "GPUCache"),  "Discord GPU cache"),
            (p("Library", "Application Support", "discord", "Code Cache"),"Discord code cache"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: "Discord — \($0.1)", detail: $0.0) }
            .sorted { $0.size > $1.size }
    }

    static func scanTeams() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("Library", "Application Support", "Microsoft", "Teams"),   "Teams cache (legacy)"),
            (p("Library", "Group Containers", "UBF8T346G9.com.microsoft.teams"), "Teams container (new)"),
            (p("Library", "Containers", "com.microsoft.teams2"),           "Teams 2 container"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: "Teams — \($0.1)", detail: $0.0) }
            .sorted { $0.size > $1.size }
    }

    // ──────────────────────────────────────────────────────────────
    // MARK: Developer – Xcode
    // ──────────────────────────────────────────────────────────────

    static func scanXcodeData() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("Library", "Developer", "Xcode", "DerivedData"),           "Xcode DerivedData (build artifacts)"),
            (p("Library", "Developer", "Xcode", "iOS DeviceSupport"),     "iOS DeviceSupport (per device OS)"),
            (p("Library", "Developer", "Xcode", "watchOS DeviceSupport"), "watchOS DeviceSupport"),
            (p("Library", "Developer", "Xcode", "tvOS DeviceSupport"),    "tvOS DeviceSupport"),
            (p("Library", "Developer", "Xcode", "visionOS DeviceSupport"),"visionOS DeviceSupport"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: $0.1, detail: $0.0) }
    }

    static func scanXcodeSimulators() async -> [CleanupItem] {
        // Use xcrun simctl to prune unavailable simulators
        let devicesPath = p("Library", "Developer", "CoreSimulator", "Devices")
        let runtimesPath = p("Library", "Developer", "CoreSimulator", "Profiles", "Runtimes")

        var items: [CleanupItem] = []

        // Simulator runtimes (large, per-OS downloads)
        if fm.fileExists(atPath: runtimesPath) {
            let size = dirSize(URL(fileURLWithPath: runtimesPath))
            if size > 0 {
                items.append(CleanupItem(
                    url: URL(fileURLWithPath: runtimesPath),
                    displayName: "Simulator Runtimes",
                    detail: "Per-OS-version simulator images — use Xcode Settings > Platforms to manage",
                    size: size, isSelected: false,
                    deleteStrategy: .shell("xcrun simctl runtime delete all 2>/dev/null; true")
                ))
            }
        }

        // Unavailable simulator devices
        let output = shell("xcrun simctl list devices unavailable 2>/dev/null | grep -c 'Unavailable'")
        let count = Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let devicesSize = dirSize(URL(fileURLWithPath: devicesPath))
        if devicesSize > 0 {
            items.append(CleanupItem(
                url: URL(fileURLWithPath: devicesPath),
                displayName: "Unavailable Simulator Devices (\(count > 0 ? "\(count)+" : "some") found)",
                detail: "Prunes devices for removed simulator runtimes",
                size: devicesSize / 10, // rough estimate of prunable portion
                isSelected: true,
                deleteStrategy: .shell("xcrun simctl delete unavailable 2>/dev/null; true")
            ))
        }
        return items
    }

    static func scanXcodeArchives() -> [CleanupItem] {
        subdirs(
            of: URL(fileURLWithPath: p("Library", "Developer", "Xcode", "Archives")),
            defaultSelected: false  // Caution: archives may be needed for crash symbolication
        )
    }

    // ──────────────────────────────────────────────────────────────
    // MARK: Developer – Package managers & caches
    // ──────────────────────────────────────────────────────────────

    static func scanNpm() -> [CleanupItem] {
        [singleItem(p(".npm", "_cacache"), displayName: "npm cache", detail: "~/.npm/_cacache",
                    deleteStrategy: .shell("npm cache clean --force 2>/dev/null; true"))
        ].compactMap { $0 }
    }

    static func scanYarn() -> [CleanupItem] {
        let paths = [
            p(".yarn", "cache"),
            p("Library", "Caches", "Yarn"),
            p("Library", "Caches", "yarn"),
        ]
        return paths.compactMap { singleItem($0, displayName: "Yarn cache", detail: $0) }
    }

    static func scanPip() -> [CleanupItem] {
        [singleItem(p("Library", "Caches", "pip"), displayName: "pip cache",
                    detail: "Python pip download cache")].compactMap { $0 }
    }

    static func scanHomebrew() -> [CleanupItem] {
        [singleItem(p("Library", "Caches", "Homebrew"), displayName: "Homebrew cache",
                    detail: "Cached Homebrew formula downloads",
                    deleteStrategy: .shell("brew cleanup --prune=all 2>/dev/null; true"))
        ].compactMap { $0 }
    }

    static func scanGradle() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p(".gradle", "caches"),          "Gradle dependency cache"),
            (p(".gradle", "wrapper", "dists"), "Gradle wrapper distributions"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: $0.1, detail: $0.0) }
    }

    static func scanMaven() -> [CleanupItem] {
        [singleItem(p(".m2", "repository"), displayName: "Maven local repository",
                    detail: "~/.m2/repository — all downloaded JARs")].compactMap { $0 }
    }

    static func scanCargo() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p(".cargo", "registry"), "Cargo registry cache"),
            (p(".cargo", "git"),      "Cargo git cache"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: $0.1, detail: $0.0) }
    }

    static func scanGo() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("go", "pkg", "mod"),      "Go module cache (~go/pkg/mod)"),
            (p(".cache", "go-build"),    "Go build cache (~/.cache/go-build)"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: $0.1, detail: $0.0,
                                              deleteStrategy: .shell("go clean -cache -modcache 2>/dev/null; true")) }
    }

    static func scanNodeModules() -> [CleanupItem] {
        var items: [CleanupItem] = []
        let searchRoot = home
        guard let enumerator = fm.enumerator(
            at: searchRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let homeComponents = home.pathComponents.count

        for case let url as URL in enumerator {
            // Limit search depth to avoid scanning deep into build dirs
            let depth = url.pathComponents.count - homeComponents
            guard depth <= 8 else { enumerator.skipDescendants(); continue }

            guard
                let vals = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                vals.isDirectory == true,
                url.lastPathComponent == "node_modules"
            else { continue }

            enumerator.skipDescendants()
            let size = dirSize(url)
            guard size > 1024 * 1024 else { continue }

            let project = url.deletingLastPathComponent().lastPathComponent
            items.append(CleanupItem(
                url: url,
                displayName: "\(project)/node_modules",
                detail: url.path,
                size: size,
                isSelected: false,   // User should decide per-project
                deleteStrategy: .permanent
            ))
        }
        return items.sorted { $0.size > $1.size }
    }

    static func scanPythonVenvs() -> [CleanupItem] {
        var items: [CleanupItem] = []
        let markers = Set(["venv", ".venv", "env", ".env"])
        guard let enumerator = fm.enumerator(
            at: home,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        let homeComponents = home.pathComponents.count

        for case let url as URL in enumerator {
            let depth = url.pathComponents.count - homeComponents
            guard depth <= 8 else { enumerator.skipDescendants(); continue }

            guard
                let vals = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                vals.isDirectory == true,
                markers.contains(url.lastPathComponent)
            else { continue }

            // Verify it's actually a Python venv
            let cfg = url.appendingPathComponent("pyvenv.cfg")
            guard fm.fileExists(atPath: cfg.path) else { continue }
            enumerator.skipDescendants()

            let size = dirSize(url)
            guard size > 5 * 1024 * 1024 else { continue }

            let project = url.deletingLastPathComponent().lastPathComponent
            items.append(CleanupItem(
                url: url,
                displayName: "\(project)/\(url.lastPathComponent)",
                detail: url.path,
                size: size,
                isSelected: false,
                deleteStrategy: .permanent
            ))
        }
        return items.sorted { $0.size > $1.size }
    }

    static func scanConda() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("anaconda3", "pkgs"),   "Anaconda package cache"),
            (p("miniconda3", "pkgs"),  "Miniconda package cache"),
            (p("miniforge3", "pkgs"),  "Miniforge package cache"),
            (p("opt", "anaconda3", "pkgs"), "Anaconda package cache (opt)"),
            (p("opt", "miniconda3", "pkgs"), "Miniconda package cache (opt)"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: $0.1, detail: $0.0,
                                              deleteStrategy: .shell("conda clean --all -y 2>/dev/null; true")) }
    }

    static func scanJetBrains() -> [CleanupItem] {
        subdirs(of: URL(fileURLWithPath: p("Library", "Caches", "JetBrains")))
    }

    static func scanVSCode() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("Library", "Caches", "com.microsoft.VSCode"),              "VS Code cache"),
            (p("Library", "Caches", "com.microsoft.VSCode.helper"),       "VS Code helper cache"),
            (p("Library", "Application Support", "Code", "User", "workspaceStorage"),
             "VS Code workspace storage (stale entries from deleted projects)"),
            (p("Library", "Application Support", "Cursor", "Cache"),      "Cursor cache"),
            (p("Library", "Application Support", "Cursor", "CachedData"), "Cursor cached data"),
            (p("Library", "Caches", "dev.zed.Zed"),                       "Zed editor cache"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: $0.1, detail: $0.0) }
            .sorted { $0.size > $1.size }
    }

    static func scanAndroidStudio() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p(".android", "avd"),          "Android Virtual Devices (emulators)"),
            (p("Library", "Android", "sdk"), "Android SDK (platforms, build tools)"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: $0.1, detail: $0.0, defaultSelected: false) }
    }

    static func scanCocoaPods() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p("Library", "Caches", "CocoaPods"), "CocoaPods download cache"),
            (p(".cocoapods", "repos"),             "CocoaPods spec repos"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: $0.1, detail: $0.0) }
    }

    static func scanFlutter() -> [CleanupItem] {
        let paths: [(String, String)] = [
            (p(".pub-cache"),        "Dart/Flutter pub package cache"),
            (p(".flutter-devtools"), "Flutter DevTools cache"),
        ]
        return paths.compactMap { singleItem($0.0, displayName: $0.1, detail: $0.0) }
    }

    static func scanTerraform() -> [CleanupItem] {
        [singleItem(p(".terraform.d", "plugin-cache"),
                    displayName: "Terraform provider plugin cache",
                    detail: "~/.terraform.d/plugin-cache")
        ].compactMap { $0 }
    }

    static func scanNvm() -> [CleanupItem] {
        subdirs(of: URL(fileURLWithPath: p(".nvm", "versions", "node")),
                defaultSelected: false,   // Don't auto-select — user may need specific versions
                minSize: 10 * 1024)
    }

    static func scanRubyGems() -> [CleanupItem] {
        [singleItem(p(".gem"), displayName: "Ruby gems (~/.gem)",
                    detail: "User-installed Ruby gems")].compactMap { $0 }
    }

    // ──────────────────────────────────────────────────────────────
    // MARK: Containers & VMs
    // ──────────────────────────────────────────────────────────────

    static func scanDocker() -> [CleanupItem] {
        let rawPath = p("Library", "Containers", "com.docker.docker", "Data", "vms", "0", "data", "Docker.raw")
        let orbPath = p("Library", "Group Containers", "HUAQ24HBR6.dev.orbstack", "data")
        let colimaPath = p(".colima")

        var items: [CleanupItem] = []

        if fm.fileExists(atPath: rawPath) {
            let size = Int64((try? URL(fileURLWithPath: rawPath).resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0)
            if size > 0 {
                items.append(CleanupItem(
                    url: nil,
                    displayName: "Docker — prune unused images & containers",
                    detail: "Runs: docker system prune -af --volumes  ·  Docker.raw = \(Fmt.bytes(size))",
                    size: size / 4, // show conservative estimate of prunable space
                    isSelected: false, // Caution: destructive
                    deleteStrategy: .shell("docker system prune -af --volumes 2>/dev/null; true")
                ))
            }
        }
        if let item = singleItem(orbPath, displayName: "OrbStack data", detail: orbPath, defaultSelected: false) {
            items.append(item)
        }
        if let item = singleItem(colimaPath, displayName: "Colima VM data", detail: colimaPath, defaultSelected: false) {
            items.append(item)
        }
        return items
    }

    // ──────────────────────────────────────────────────────────────
    // MARK: Orphaned leftovers
    // ──────────────────────────────────────────────────────────────

    static func installedBundleIDs() -> Set<String> {
        var ids = Set<String>()
        let appDirs = ["/Applications", p("Applications")]
        for dir in appDirs {
            guard let apps = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for app in apps where app.hasSuffix(".app") {
                let plistPath = "\(dir)/\(app)/Contents/Info.plist"
                if let plist = NSDictionary(contentsOfFile: plistPath),
                   let bid = plist["CFBundleIdentifier"] as? String {
                    ids.insert(bid)
                }
            }
        }
        return ids
    }

    static func scanOrphanedContainers() -> [CleanupItem] {
        let containerDir = URL(fileURLWithPath: p("Library", "Containers"))
        guard fm.fileExists(atPath: containerDir.path) else { return [] }
        let installed = installedBundleIDs()
        return subdirs(of: containerDir, defaultSelected: false)
            .filter { item in
                guard let name = item.url?.lastPathComponent else { return false }
                return !installed.contains(name)
            }
    }

    static func scanOrphanedAppSupport() -> [CleanupItem] {
        let supportDir = URL(fileURLWithPath: p("Library", "Application Support"))
        guard fm.fileExists(atPath: supportDir.path) else { return [] }
        let installed = installedBundleIDs()
        // Exclude well-known system/Apple folders
        let systemFolders: Set<String> = [
            "Apple", "com.apple", "CloudDocs", "SyncServices",
            "AddressBook", "CallHistoryDB", "CallHistoryTransactions",
            "MobileSync", "coreMLCache", "Dock", "Finder",
            "iCloud", "Knowledge", "NGL", "Podcasts"
        ]
        return subdirs(of: supportDir, defaultSelected: false, minSize: 5 * 1024 * 1024)
            .filter { item in
                guard let name = item.url?.lastPathComponent else { return false }
                if systemFolders.contains(where: { name.hasPrefix($0) }) { return false }
                // Only show if it doesn't match an installed app's bundle ID
                return !installed.contains(where: { $0.hasSuffix(name) || name == $0 })
            }
    }
}
