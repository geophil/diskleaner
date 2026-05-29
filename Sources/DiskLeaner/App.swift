import SwiftUI

@main
struct DiskLeanerApp: App {
    @StateObject private var scanner = DiskScanner()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scanner)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Clean") {
                Button("Scan My Mac") {
                    Task { @MainActor in await scanner.scanAll() }
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(scanner.isScanning)
            }
        }
    }
}
