import Foundation

@MainActor
@Observable
final class TerminalPaneState: Identifiable {
    let id: UUID
    let projectPath: String
    var title: String
    var currentWorkingDirectory: String?
    let startupCommand: String?
    let startupFallbackCommand: String?
    let startupCommandInteractive: Bool
    let externalEditorFilePath: String?
    let restoredSession: TerminalSessionSnapshot?
    var activeRestoredCommand: String?
    var restoreDecision: TerminalSessionRestoreDecision = .none
    var restoreConsumed = false
    let searchState = TerminalSearchState()
    let branchObserver = PaneBranchObserver()
    @ObservationIgnored private var titleDebounceTask: Task<Void, Never>?

    init(
        id: UUID = UUID(),
        projectPath: String,
        title: String = "Terminal",
        initialWorkingDirectory: String? = nil,
        startupCommand: String? = nil,
        startupFallbackCommand: String? = nil,
        startupCommandInteractive: Bool = false,
        externalEditorFilePath: String? = nil,
        restoredSession: TerminalSessionSnapshot? = nil
    ) {
        self.id = id
        self.projectPath = projectPath
        self.title = title
        self.currentWorkingDirectory = initialWorkingDirectory
        self.startupCommand = startupCommand
        self.startupFallbackCommand = startupFallbackCommand
        self.startupCommandInteractive = startupCommandInteractive
        self.externalEditorFilePath = externalEditorFilePath
        self.restoredSession = restoredSession
        branchObserver.update(repoPath: initialWorkingDirectory ?? projectPath)
        if let restoredSession {
            let decision = TerminalSessionRestorePolicy.decision(for: restoredSession)
            restoreDecision = decision
            if case let .command(launch) = decision {
                activeRestoredCommand = launch.command
            }
        }
    }

    func consumeRestoredLaunch() -> TerminalPaneLaunch {
        guard !restoreConsumed else {
            return TerminalPaneLaunch(
                command: startupCommand,
                fallbackCommand: startupFallbackCommand,
                interactive: startupCommandInteractive
            )
        }
        restoreConsumed = true
        switch restoreDecision {
        case .none:
            return TerminalPaneLaunch(
                command: startupCommand,
                fallbackCommand: startupFallbackCommand,
                interactive: startupCommandInteractive
            )
        case let .command(launch):
            return TerminalPaneLaunch(command: launch.command, fallbackCommand: launch.fallbackCommand, interactive: true)
        }
    }

    func setTitle(_ newTitle: String) {
        titleDebounceTask?.cancel()
        titleDebounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let self, self.title != newTitle else { return }
            self.title = newTitle
        }
    }

    func setWorkingDirectory(_ path: String) {
        currentWorkingDirectory = path
        branchObserver.update(repoPath: path)
    }
}

struct TerminalPaneLaunch {
    let command: String?
    let fallbackCommand: String?
    let interactive: Bool
}
