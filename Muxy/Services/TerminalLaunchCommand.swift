import Darwin
import Foundation

enum TerminalLaunchCommand {
    static let environmentKey = "MUXY_STARTUP_COMMAND"
    static let restoreCompleteSentinel = "__muxy_restore_done__"

    static func shellCommand(interactive: Bool, dropsToShell: Bool = false, shell: String = userShell()) -> String {
        let flags = interactive ? "-l -i" : "-l"
        let escapedShell = ShellEscaper.escape(shell)
        let activeScript = dropsToShell ? persistentScript : script
        return "\(escapedShell) \(flags) -c '\(activeScript)' \(escapedShell)"
    }

    private static var script: String {
        [
            "eval \"$\(environmentKey)\"",
            "muxy_status=$?",
            "if [ $muxy_status -ne 0 ]",
            "then exec \"$0\" -l",
            "else exit $muxy_status",
            "fi",
        ].joined(separator: "; ")
    }

    private static var persistentScript: String {
        [
            "eval \"$\(environmentKey)\"",
            "printf \"\\033]0;\(restoreCompleteSentinel)%s\\007\" \"${PWD##*/}\"",
            "exec \"$0\" -l",
        ].joined(separator: "; ")
    }

    private static func userShell() -> String {
        if let shell = ProcessInfo.processInfo.environment["SHELL"], !shell.isEmpty {
            return shell
        }
        guard let pw = getpwuid(getuid()), let shellPtr = pw.pointee.pw_shell else {
            return "/bin/zsh"
        }
        return String(cString: shellPtr)
    }
}
