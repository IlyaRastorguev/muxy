import Foundation

enum SessionRestorePreferences {
    static let enabledKey = "muxy.sessionRestore.enabled"
    static let excludedCommandsKey = "muxy.sessionRestore.excludedCommands"
    static let maxSnapshotsKey = "muxy.sessionRestore.maxSnapshots"

    static var isEnabled: Bool {
        get {
            let defaults = UserDefaults.standard
            if defaults.object(forKey: enabledKey) == nil { return true }
            return defaults.bool(forKey: enabledKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var excludedCommands: [String] {
        get { UserDefaults.standard.stringArray(forKey: excludedCommandsKey) ?? defaultExcludedCommands }
        set { UserDefaults.standard.set(newValue, forKey: excludedCommandsKey) }
    }

    static var excludedCommandsText: String {
        get { excludedCommands.joined(separator: "\n") }
        set {
            excludedCommands = newValue
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
    }

    static var maxSnapshots: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: maxSnapshotsKey)
            return value > 0 ? max(20, value) : 200
        }
        set { UserDefaults.standard.set(max(20, newValue), forKey: maxSnapshotsKey) }
    }

    static let defaultExcludedCommands = [
        "rm",
        "rmdir",
        "mv",
        "git push --force",
        "git push -f",
        "git reset --hard",
        "git clean",
        "docker system prune",
        "sudo",
    ]
}
