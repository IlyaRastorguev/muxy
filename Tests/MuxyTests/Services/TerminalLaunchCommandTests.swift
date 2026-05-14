import Testing

@testable import Muxy

@Suite("TerminalLaunchCommand")
struct TerminalLaunchCommandTests {
    @Test("Builds non-interactive login shell command")
    func buildsNonInteractiveLoginShellCommand() {
        #expect(TerminalLaunchCommand.shellCommand(interactive: false, shell: "/bin/zsh") == "/bin/zsh -l -c 'eval \"$MUXY_STARTUP_COMMAND\"'")
    }

    @Test("Builds interactive login shell command")
    func buildsInteractiveLoginShellCommand() {
        #expect(TerminalLaunchCommand.shellCommand(interactive: true, shell: "/bin/zsh") == "/bin/zsh -l -i -c 'eval \"$MUXY_STARTUP_COMMAND\"'")
    }

    @Test("Launch wrapper does not embed user command")
    func launchWrapperDoesNotEmbedUserCommand() {
        let command = TerminalLaunchCommand.shellCommand(interactive: true, shell: "/bin/zsh")
        #expect(!command.contains("/Users/some user/Library/Application Support/some file.json"))
    }

    @Test("Escapes shell path in launch wrapper")
    func escapesShellPathInLaunchWrapper() {
        let command = TerminalLaunchCommand.shellCommand(interactive: false, shell: "/tmp/my shell;touch /tmp/pwn")
        #expect(command == "'/tmp/my shell;touch /tmp/pwn' -l -c 'eval \"$MUXY_STARTUP_COMMAND\"'")
    }
}
