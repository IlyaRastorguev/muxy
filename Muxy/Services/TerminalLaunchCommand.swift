import Darwin
import Foundation

enum TerminalLaunchCommand {
    static let environmentKey = "MUXY_STARTUP_COMMAND"

    static func shellCommand(interactive: Bool, shell: String = userShell()) -> String {
        let flags = interactive ? "-l -i" : "-l"
        return "\(shell) \(flags) -c 'eval \"$\(environmentKey)\"'"
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
