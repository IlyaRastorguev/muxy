import Foundation

struct OpenTerminalTabItem: Identifiable, Equatable {
    let projectID: UUID
    let worktreeID: UUID
    let areaID: UUID
    let tabID: UUID
    let title: String
    let workingDirectory: String?
    let command: String?

    var id: String { "open-\(areaID.uuidString)-\(tabID.uuidString)" }

    var searchKey: String {
        [title, workingDirectory, command].compactMap(\.self).joined(separator: " ")
    }
}

struct TerminalOmniboxProjectItem: Identifiable, Equatable {
    let projectID: UUID
    let name: String
    let path: String

    var id: String { "project-\(projectID.uuidString)" }

    var searchKey: String {
        [name, path, "project"].joined(separator: " ")
    }
}

struct TerminalOmniboxWorktreeItem: Identifiable, Equatable {
    let projectID: UUID
    let worktreeID: UUID
    let name: String
    let path: String
    let branch: String?
    let isPrimary: Bool

    var id: String { "worktree-\(worktreeID.uuidString)" }

    var searchKey: String {
        [name, path, branch ?? "", "worktree"].joined(separator: " ")
    }
}

enum TerminalOmniboxItem: Identifiable, Equatable {
    case project(TerminalOmniboxProjectItem)
    case worktree(TerminalOmniboxWorktreeItem)
    case openTab(OpenTerminalTabItem)
    case closedTab(ClosedTerminalTabSnapshot)
    case commandShortcut(CommandShortcut)
    case typedCommand(String)

    var id: String {
        switch self {
        case let .project(project):
            project.id
        case let .worktree(wt):
            wt.id
        case let .openTab(tab):
            tab.id
        case let .closedTab(snapshot):
            "closed-\(snapshot.id.uuidString)"
        case let .commandShortcut(shortcut):
            "shortcut-\(shortcut.id.uuidString)"
        case let .typedCommand(command):
            "typed-\(command)"
        }
    }

    var title: String {
        switch self {
        case let .project(project):
            project.name
        case let .worktree(wt):
            wt.name
        case let .openTab(tab):
            tab.title
        case let .closedTab(snapshot):
            snapshot.title
        case let .commandShortcut(shortcut):
            shortcut.displayName
        case let .typedCommand(command):
            command
        }
    }

    var subtitle: String? {
        switch self {
        case let .project(project):
            project.path
        case let .worktree(wt):
            wt.branch.map { "(\($0)) \(wt.path)" } ?? wt.path
        case let .openTab(tab):
            tab.command ?? tab.workingDirectory
        case let .closedTab(snapshot):
            snapshot.commandToRestore ?? snapshot.workingDirectory
        case let .commandShortcut(shortcut):
            shortcut.trimmedCommand
        case .typedCommand:
            "Run in new tab"
        }
    }

    var sectionTitle: String {
        switch self {
        case .project:
            "Projects"
        case .worktree:
            "Worktrees"
        case .openTab:
            "Open Tabs"
        case .closedTab:
            "History"
        case .commandShortcut:
            "Custom Commands"
        case .typedCommand:
            "New Command"
        }
    }

    var symbol: String {
        switch self {
        case .project:
            "folder"
        case let .worktree(wt):
            wt.isPrimary ? "folder.badge.gearshape" : "arrow.triangle.branch"
        case .openTab:
            "terminal"
        case .closedTab:
            "clock.arrow.circlepath"
        case .commandShortcut:
            "command"
        case .typedCommand:
            "plus"
        }
    }

    var searchKey: String {
        switch self {
        case let .project(project):
            project.searchKey
        case let .worktree(wt):
            wt.searchKey
        case let .openTab(tab):
            tab.searchKey
        case let .closedTab(snapshot):
            [
                snapshot.title,
                snapshot.workingDirectory,
                snapshot.commandToRestore,
            ].compactMap(\.self).joined(separator: " ")
        case let .commandShortcut(shortcut):
            [shortcut.displayName, shortcut.trimmedCommand].joined(separator: " ")
        case let .typedCommand(command):
            command
        }
    }
}
