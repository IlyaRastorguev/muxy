import Foundation
import Testing
@testable import Muxy

@Suite("TerminalSessionRestorePolicy")
struct TerminalSessionRestorePolicyTests {
    @Test("Allows commands that are not blocked")
    func allowsCommandsThatAreNotBlocked() {
        #expect(TerminalSessionRestorePolicy.isSafeToRestore("nvim Package.swift"))
        #expect(TerminalSessionRestorePolicy.isSafeToRestore("lazygit"))
        #expect(TerminalSessionRestorePolicy.isSafeToRestore("npm run dev"))
        #expect(TerminalSessionRestorePolicy.isSafeToRestore("ssh user@example.com"))
        #expect(TerminalSessionRestorePolicy.isSafeToRestore("custom-tool --watch"))
    }

    @Test("Blocks excluded commands across shell segments")
    func blocksDangerousCommands() {
        #expect(!TerminalSessionRestorePolicy.isSafeToRestore("rm -rf build"))
        #expect(!TerminalSessionRestorePolicy.isSafeToRestore("git push --force origin main"))
        #expect(!TerminalSessionRestorePolicy.isSafeToRestore("npm run dev && rm -rf build"))
        #expect(!TerminalSessionRestorePolicy.isSafeToRestore("sudo npm run dev"))
    }

    @Test("Rewrites AI tool launches to continue previous conversations")
    func rewritesAIToolLaunches() {
        #expect(TerminalAIRestoreCommand.rewriting("codex") == "codex resume --last")
        #expect(TerminalAIRestoreCommand.rewriting("codex --model gpt-5") == "codex resume --last --model gpt-5")
        #expect(TerminalAIRestoreCommand.rewriting("claude") == "claude --continue")
        #expect(TerminalAIRestoreCommand.rewriting("agent --model sonnet") == "agent --continue --model sonnet")
        #expect(TerminalAIRestoreCommand.rewriting("opencode") == "opencode --continue")
    }

    @Test("Keeps explicit AI conversation restore commands")
    func keepsExplicitAIConversationRestoreCommands() {
        #expect(TerminalAIRestoreCommand.rewriting("codex resume abc123") == "codex resume abc123")
        #expect(TerminalAIRestoreCommand.rewriting("claude --continue") == "claude --continue")
        #expect(TerminalAIRestoreCommand.rewriting("agent --resume abc123") == "agent --resume abc123")
        #expect(TerminalAIRestoreCommand.rewriting("opencode --continue") == "opencode --continue")
    }

    @Test("Does not rewrite AI tools inside compound shell commands")
    func doesNotRewriteCompoundAICommands() {
        #expect(TerminalAIRestoreCommand.rewriting("echo ready && codex") == "echo ready && codex")
    }

    @Test("Rewrites AI tools invoked via absolute path")
    func rewritesAbsolutePathAITools() {
        #expect(TerminalAIRestoreCommand.rewriting("/usr/local/bin/claude") == "/usr/local/bin/claude --continue")
        #expect(TerminalAIRestoreCommand.rewriting("/opt/homebrew/bin/codex") == "/opt/homebrew/bin/codex resume --last")
    }

    @Test("Rewrites AI tools with quoted arguments")
    func rewritesAIToolsWithQuotedArguments() {
        #expect(TerminalAIRestoreCommand.rewriting("claude \"fix the bug\"") == "claude --continue 'fix the bug'")
        #expect(TerminalAIRestoreCommand.rewriting("codex 'review changes'") == "codex resume --last 'review changes'")
    }

    @Test("Leaves empty and whitespace-only commands unchanged")
    func leavesEmptyCommandsUnchanged() {
        #expect(TerminalAIRestoreCommand.rewriting("") == "")
        #expect(TerminalAIRestoreCommand.rewriting("   ") == "   ")
    }

    @Test("Leaves non-AI commands unchanged")
    func leavesNonAICommandsUnchanged() {
        #expect(TerminalAIRestoreCommand.rewriting("vim main.swift") == "vim main.swift")
        #expect(TerminalAIRestoreCommand.rewriting("npm run dev") == "npm run dev")
    }

    @Test("Blocks commands that are prefixes of excluded patterns")
    func blocksPrefixExcludedCommands() {
        #expect(!TerminalSessionRestorePolicy.isSafeToRestore("rm file.txt"))
        #expect(!TerminalSessionRestorePolicy.isSafeToRestore("sudo apt install vim"))
        #expect(!TerminalSessionRestorePolicy.isSafeToRestore("git push -f origin main"))
    }

    @Test("Does not block commands that merely contain an excluded word")
    func doesNotBlockCommandsContainingExcludedWord() {
        #expect(TerminalSessionRestorePolicy.isSafeToRestore("git log --oneline"))
        #expect(TerminalSessionRestorePolicy.isSafeToRestore("echo 'no rm here'"))
    }

    @Test("Empty and whitespace-only commands are not safe")
    func emptyCommandIsNotSafe() {
        #expect(!TerminalSessionRestorePolicy.isSafeToRestore(""))
        #expect(!TerminalSessionRestorePolicy.isSafeToRestore("   "))
    }

    @Test("Blocks excluded command in any shell segment of a pipeline")
    func blocksExcludedCommandInPipeline() {
        #expect(!TerminalSessionRestorePolicy.isSafeToRestore("find . -name '*.log' | sudo tee /dev/null"))
        #expect(!TerminalSessionRestorePolicy.isSafeToRestore("ls build; rm -rf build"))
    }

    @Test("Does not split on shell separators inside quoted strings")
    func doesNotSplitInsideQuotedStrings() {
        #expect(TerminalSessionRestorePolicy.isSafeToRestore("echo \"safe | pipe\""))
        #expect(TerminalSessionRestorePolicy.isSafeToRestore("echo 'safe; semicolon'"))
        #expect(TerminalSessionRestorePolicy.isSafeToRestore("grep -E 'foo|bar' file.txt"))
    }

    @Test("commandToRestore returns startupCommand when set")
    func commandToRestoreReturnsStartupCommand() {
        let snapshot = makeSnapshot(startupCommand: "npm run dev", lastSubmittedCommand: "git log", activity: .idle)
        #expect(snapshot.commandToRestore == "npm run dev")
    }

    @Test("commandToRestore ignores whitespace-only startupCommand")
    func commandToRestoreIgnoresWhitespaceStartupCommand() {
        let snapshot = makeSnapshot(startupCommand: "   ", lastSubmittedCommand: "git log", activity: .running)
        #expect(snapshot.commandToRestore == "git log")
    }

    @Test("commandToRestore returns nil for idle pane with no startupCommand")
    func commandToRestoreNilForIdlePaneWithNoStartupCommand() {
        let snapshot = makeSnapshot(startupCommand: nil, lastSubmittedCommand: "git log", activity: .idle)
        #expect(snapshot.commandToRestore == nil)
    }

    @Test("commandToRestore returns lastSubmittedCommand for running pane")
    func commandToRestoreReturnsLastSubmittedForRunningPane() {
        let snapshot = makeSnapshot(startupCommand: nil, lastSubmittedCommand: "claude", activity: .running)
        #expect(snapshot.commandToRestore == "claude")
    }

    @Test("commandToRestore returns nil for running pane with no lastSubmittedCommand")
    func commandToRestoreNilForRunningPaneWithNoCommand() {
        let snapshot = makeSnapshot(startupCommand: nil, lastSubmittedCommand: nil, activity: .running)
        #expect(snapshot.commandToRestore == nil)
    }

    @Test("decision returns command when safe and enabled")
    func decisionReturnsCommandWhenSafe() {
        SessionRestorePreferences.isEnabled = true
        defer { UserDefaults.standard.removeObject(forKey: SessionRestorePreferences.enabledKey) }
        let snapshot = makeSnapshot(startupCommand: nil, lastSubmittedCommand: "nvim main.swift", activity: .running)
        #expect(TerminalSessionRestorePolicy.decision(for: snapshot) == .command("nvim main.swift"))
    }

    @Test("decision returns none when feature disabled")
    func decisionNoneWhenDisabled() {
        SessionRestorePreferences.isEnabled = false
        defer { UserDefaults.standard.removeObject(forKey: SessionRestorePreferences.enabledKey) }
        let snapshot = makeSnapshot(startupCommand: nil, lastSubmittedCommand: "nvim main.swift", activity: .running)
        #expect(TerminalSessionRestorePolicy.decision(for: snapshot) == .none)
    }

    @Test("decision returns none for blocked command")
    func decisionNoneForBlockedCommand() {
        SessionRestorePreferences.isEnabled = true
        defer { UserDefaults.standard.removeObject(forKey: SessionRestorePreferences.enabledKey) }
        let snapshot = makeSnapshot(startupCommand: nil, lastSubmittedCommand: "sudo rm -rf /", activity: .running)
        #expect(TerminalSessionRestorePolicy.decision(for: snapshot) == .none)
    }

    @Test("decision rewrites AI tool command")
    func decisionRewritesAIToolCommand() {
        SessionRestorePreferences.isEnabled = true
        defer { UserDefaults.standard.removeObject(forKey: SessionRestorePreferences.enabledKey) }
        let snapshot = makeSnapshot(startupCommand: nil, lastSubmittedCommand: "claude", activity: .running)
        #expect(TerminalSessionRestorePolicy.decision(for: snapshot) == .command("claude --continue"))
    }
}

private func makeSnapshot(
    startupCommand: String?,
    lastSubmittedCommand: String?,
    activity: TerminalSessionSnapshot.Activity
) -> TerminalSessionSnapshot {
    TerminalSessionSnapshot(
        id: UUID(),
        projectID: UUID(),
        worktreeID: UUID(),
        paneID: UUID(),
        tabID: UUID(),
        areaID: UUID(),
        projectPath: "/tmp/project",
        title: "Terminal",
        workingDirectory: "/tmp/project",
        startupCommand: startupCommand,
        lastSubmittedCommand: lastSubmittedCommand,
        activity: activity,
        capturedAt: Date()
    )
}
