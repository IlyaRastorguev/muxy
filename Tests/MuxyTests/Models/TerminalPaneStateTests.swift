import Foundation
import Testing

@testable import Muxy

@Suite("TerminalPaneState")
@MainActor
struct TerminalPaneStateTests {
    @Test("launch carries command close preference")
    func launchCarriesCommandClosePreference() {
        let pane = TerminalPaneState(
            projectPath: "/tmp/project",
            startupCommand: "git status",
            startupCommandInteractive: true,
            closesOnStartupCommandExit: false
        )

        let launch = pane.consumeRestoredLaunch()

        #expect(launch.command == "git status")
        #expect(launch.interactive)
        #expect(!launch.dropsToShell)
        #expect(!launch.closesOnCommandExit)
    }

    @Test("restored command drops to shell instead of closing")
    func restoredCommandDropsToShellInsteadOfClosing() {
        SessionRestorePreferences.isEnabled = true
        defer { UserDefaults.standard.removeObject(forKey: SessionRestorePreferences.enabledKey) }

        let pane = TerminalPaneState(
            projectPath: "/tmp/project",
            restoredSession: TerminalSessionSnapshot(
                id: UUID(),
                projectID: UUID(),
                worktreeID: UUID(),
                paneID: UUID(),
                tabID: UUID(),
                areaID: UUID(),
                projectPath: "/tmp/project",
                title: "Terminal",
                workingDirectory: "/tmp/project",
                startupCommand: nil,
                lastSubmittedCommand: "claude",
                activity: .running,
                capturedAt: Date()
            )
        )

        let launch = pane.consumeRestoredLaunch()

        #expect(launch.command == "claude")
        #expect(launch.interactive)
        #expect(launch.dropsToShell)
        #expect(!launch.closesOnCommandExit)
    }

    @Test("restored tab launch drops to shell after app restart")
    func restoredTabLaunchDropsToShellAfterAppRestart() {
        SessionRestorePreferences.isEnabled = true
        defer { UserDefaults.standard.removeObject(forKey: SessionRestorePreferences.enabledKey) }

        let paneID = UUID()
        let tab = TerminalTab(
            restoring: TerminalTabSnapshot(
                kind: .terminal,
                customTitle: nil,
                colorID: nil,
                isPinned: false,
                projectPath: "/tmp/project",
                paneTitle: "Claude",
                paneID: paneID
            ),
            restoredSession: TerminalSessionSnapshot(
                id: UUID(),
                projectID: UUID(),
                worktreeID: UUID(),
                paneID: paneID,
                tabID: UUID(),
                areaID: UUID(),
                projectPath: "/tmp/project",
                title: "Claude",
                workingDirectory: "/tmp/project",
                startupCommand: nil,
                lastSubmittedCommand: "claude",
                activity: .running,
                capturedAt: Date()
            )
        )

        let launch = tab.content.pane?.consumeRestoredLaunch()

        #expect(launch?.command == "claude")
        #expect(launch?.dropsToShell == true)
        #expect(launch?.closesOnCommandExit == false)
    }

    @Test("finishing restored command sets cwd title and ignores empty title")
    func finishingRestoredCommandSetsCWDTitleAndIgnoresEmptyTitle() {
        SessionRestorePreferences.isEnabled = true
        defer { UserDefaults.standard.removeObject(forKey: SessionRestorePreferences.enabledKey) }

        let pane = TerminalPaneState(
            projectPath: "/tmp/project",
            title: "Claude",
            initialWorkingDirectory: "/tmp/project",
            restoredSession: TerminalSessionSnapshot(
                id: UUID(),
                projectID: UUID(),
                worktreeID: UUID(),
                paneID: UUID(),
                tabID: UUID(),
                areaID: UUID(),
                projectPath: "/tmp/project",
                title: "Claude",
                workingDirectory: "/tmp/project",
                startupCommand: nil,
                lastSubmittedCommand: "claude",
                activity: .running,
                capturedAt: Date()
            )
        )

        pane.finishRestoredCommand()
        pane.setTitle("")

        #expect(pane.restoredCommandFinished)
        #expect(pane.title == "project")
    }
}
