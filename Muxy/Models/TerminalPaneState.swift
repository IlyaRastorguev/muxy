import Foundation

struct TerminalPaneLaunch: Equatable {
    let command: String?
    let interactive: Bool
    let closesOnCommandExit: Bool
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

    struct RestoredLaunch {
        let command: String?
        let interactive: Bool
        let dropsToShell: Bool
        let closesOnCommandExit: Bool
    }

    func consumeRestoredLaunch() -> RestoredLaunch {
        guard !restoreConsumed else {
            return RestoredLaunch(
                command: startupCommand,
                interactive: startupCommandInteractive,
                dropsToShell: false,
                closesOnCommandExit: closesOnStartupCommandExit
            )
        }
        restoreConsumed = true
        switch restoreDecision {
        case .none:
            return RestoredLaunch(
                command: startupCommand,
                interactive: startupCommandInteractive,
                dropsToShell: false,
                closesOnCommandExit: closesOnStartupCommandExit
            )
        case let .command(command):
            return RestoredLaunch(command: command, interactive: true, dropsToShell: true, closesOnCommandExit: false)
        }
    }

    func setTitle(_ newTitle: String) {
        guard !newTitle.isEmpty else { return }
        titleDebounceTask?.cancel()
        titleDebounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, let self, self.title != newTitle else { return }
            self.title = newTitle
        }
    }

    func finishRestoredCommand() {
        guard activeRestoredCommand != nil else { return }
        restoredCommandFinished = true
        let path = currentWorkingDirectory ?? projectPath
        let directoryName = URL(fileURLWithPath: path).lastPathComponent
        setImmediateTitle(directoryName.isEmpty ? path : directoryName)
    }

    func setWorkingDirectory(_ path: String) {
        currentWorkingDirectory = path
        branchObserver.update(repoPath: path)
    }

    private func setImmediateTitle(_ newTitle: String) {
        guard !newTitle.isEmpty else { return }
        titleDebounceTask?.cancel()
        guard title != newTitle else { return }
        title = newTitle
    }
}
