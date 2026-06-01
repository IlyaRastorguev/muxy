import Foundation

struct TerminalPaneLaunch: Equatable {
    let command: String?
    let interactive: Bool
    let closesOnCommandExit: Bool
    let dropsToShell: Bool

    init(command: String?, interactive: Bool, closesOnCommandExit: Bool, dropsToShell: Bool = false) {
        self.command = command
        self.interactive = interactive
        self.closesOnCommandExit = closesOnCommandExit
        self.dropsToShell = dropsToShell
    }
}

@MainActor
@Observable
final class TerminalPaneState: Identifiable {
    let id: UUID
    let projectPath: String
    var title: String
    var currentWorkingDirectory: String?
    let startupCommand: String?
    let startupCommandInteractive: Bool
    let closesOnStartupCommandExit: Bool
    let externalEditorFilePath: String?
    let restoredSession: TerminalSessionSnapshot?
    var activeRestoredCommand: String?
    var restoredCommandFinished = false
    var isRestorationDeferred: Bool
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
        startupCommandInteractive: Bool = false,
        closesOnStartupCommandExit: Bool = true,
        externalEditorFilePath: String? = nil,
        restoredSession: TerminalSessionSnapshot? = nil,
        isRestorationDeferred: Bool = false
    ) {
        self.id = id
        self.projectPath = projectPath
        self.title = title
        self.currentWorkingDirectory = initialWorkingDirectory
        self.startupCommand = startupCommand
        self.startupCommandInteractive = startupCommandInteractive
        self.closesOnStartupCommandExit = closesOnStartupCommandExit
        self.externalEditorFilePath = externalEditorFilePath
        self.restoredSession = restoredSession
        self.isRestorationDeferred = isRestorationDeferred
        branchObserver.update(repoPath: initialWorkingDirectory ?? projectPath, refresh: false)
        if let restoredSession {
            let decision = TerminalSessionRestorePolicy.decision(for: restoredSession)
            restoreDecision = decision
            if case let .command(command) = decision {
                activeRestoredCommand = command
            }
        }
    }

    func activateDeferredRestoration() {
        isRestorationDeferred = false
    }

    func consumeRestoredLaunch() -> TerminalPaneLaunch {
        guard !restoreConsumed else {
            return TerminalPaneLaunch(
                command: startupCommand,
                interactive: startupCommandInteractive,
                closesOnCommandExit: closesOnStartupCommandExit
            )
        }
        restoreConsumed = true
        switch restoreDecision {
        case .none:
            return TerminalPaneLaunch(
                command: startupCommand,
                interactive: startupCommandInteractive,
                closesOnCommandExit: closesOnStartupCommandExit
            )
        case let .command(command):
            return TerminalPaneLaunch(command: command, interactive: true, closesOnCommandExit: false, dropsToShell: true)
        }
    }

    func setTitle(_ newTitle: String) {
        let resolvedTitle = newTitle.isEmpty ? fallbackTitle : newTitle
        titleDebounceTask?.cancel()
        titleDebounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let self, self.title != resolvedTitle else { return }
            self.title = resolvedTitle
        }
    }

    private var fallbackTitle: String {
        guard let cwd = currentWorkingDirectory, !cwd.isEmpty else { return "Terminal" }
        return cwd
    }

    func setWorkingDirectory(_ path: String) {
        currentWorkingDirectory = path
        branchObserver.update(repoPath: path)
    }
}
