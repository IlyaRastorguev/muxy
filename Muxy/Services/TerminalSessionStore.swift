import Foundation
import os

private let terminalSessionLogger = Logger(subsystem: "app.muxy", category: "TerminalSessionStore")

@MainActor
final class TerminalSessionStore {
    static let shared = TerminalSessionStore()

    private let store: CodableFileStore<TerminalSessionFile>
    private(set) var sessionsByPaneID: [UUID: TerminalSessionSnapshot] = [:]

    private init(fileURL: URL = MuxyFileStorage.fileURL(filename: "terminal-sessions.json")) {
        store = CodableFileStore(fileURL: fileURL, options: .pretty)
        load()
    }

    func load() {
        do {
            guard let file = try store.load() else {
                sessionsByPaneID = [:]
                return
            }
            sessionsByPaneID = Dictionary(uniqueKeysWithValues: file.sessions.map { ($0.paneID, $0) })
        } catch {
            terminalSessionLogger.error("Failed to load terminal sessions: \(error)")
            sessionsByPaneID = [:]
        }
    }

    func session(for paneID: UUID) -> TerminalSessionSnapshot? {
        sessionsByPaneID[paneID]
    }

    func save(workspaceRoots: [WorktreeKey: SplitNode]) {
        guard SessionRestorePreferences.isEnabled else {
            saveFile(sessions: [])
            return
        }
        let snapshots = buildSnapshots(workspaceRoots: workspaceRoots)
            .sorted { $0.capturedAt > $1.capturedAt }
            .prefix(SessionRestorePreferences.maxSnapshots)
        saveFile(sessions: Array(snapshots))
    }

    private func buildSnapshots(workspaceRoots: [WorktreeKey: SplitNode]) -> [TerminalSessionSnapshot] {
        var snapshots: [TerminalSessionSnapshot] = []
        for (key, root) in workspaceRoots {
            for area in root.allAreas() {
                for tab in area.tabs {
                    guard let pane = tab.content.pane else { continue }
                    let view = TerminalViewRegistry.shared.existingView(for: pane.id)
                    let isRunning = view.map { $0.needsConfirmQuit() } ?? false
                    let hasRestoredCommand = pane.activeRestoredCommand != nil
                    let trackedCommand = TerminalCommandTracker.shared.lastSubmittedCommand(for: pane.id)
                        ?? pane.activeRestoredCommand
                    let activity: TerminalSessionSnapshot.Activity = isRunning || hasRestoredCommand ? .running : .idle
                    let cwd = pane.currentWorkingDirectory ?? pane.projectPath
                    snapshots.append(TerminalSessionSnapshot(
                        id: UUID(),
                        projectID: key.projectID,
                        worktreeID: key.worktreeID,
                        paneID: pane.id,
                        tabID: tab.id,
                        areaID: area.id,
                        projectPath: pane.projectPath,
                        title: pane.title,
                        workingDirectory: cwd,
                        startupCommand: pane.startupCommand,
                        lastSubmittedCommand: trackedCommand,
                        activity: activity,
                        capturedAt: Date()
                    ))
                }
            }
        }
        return snapshots
    }

    private func saveFile(sessions: [TerminalSessionSnapshot]) {
        do {
            try store.save(TerminalSessionFile(
                schemaVersion: TerminalSessionFile.currentSchemaVersion,
                sessions: sessions
            ))
            sessionsByPaneID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.paneID, $0) })
        } catch {
            terminalSessionLogger.error("Failed to save terminal sessions: \(error)")
        }
    }
}
