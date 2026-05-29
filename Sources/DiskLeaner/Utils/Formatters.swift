import Foundation

enum Fmt {
    private static let byteFormatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
        f.countStyle = .file
        f.zeroPadsFractionDigits = false
        return f
    }()

    static func bytes(_ n: Int64) -> String {
        guard n > 0 else { return "—" }
        return byteFormatter.string(fromByteCount: n)
    }
}
