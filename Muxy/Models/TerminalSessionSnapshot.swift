import Foundation

struct TerminalSessionSnapshot: Codable, Identifiable {
    enum Activity: String, Codable {
        case idle
        case running
        case unknown
    }

    let id: UUID
    let projectID: UUID
    let worktreeID: UUID
    let paneID: UUID
    let tabID: UUID
    let areaID: UUID
    let projectPath: String
    let title: String
    let workingDirectory: String
    let startupCommand: String?
    let lastSubmittedCommand: String?
    let activity: Activity
    let capturedAt: Date

    var commandToRestore: String? {
        if let startupCommand, !startupCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return startupCommand
        }
        guard activity == .running else { return nil }
        return lastSubmittedCommand?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct TerminalSessionFile: Codable {
    let schemaVersion: Int
    let sessions: [TerminalSessionSnapshot]

    static let currentSchemaVersion = 1
}

enum TerminalSessionRestoreDecision: Equatable {
    case none
    case command(String)
}

enum TerminalSessionRestorePolicy {
    static func decision(for snapshot: TerminalSessionSnapshot) -> TerminalSessionRestoreDecision {
        guard SessionRestorePreferences.isEnabled else { return .none }
        guard let command = snapshot.commandToRestore else { return .none }
        return isSafeToRestore(command) ? .command(TerminalAIRestoreCommand.rewriting(command)) : .none
    }

    static func isSafeToRestore(_ command: String) -> Bool {
        let normalized = normalize(command)
        guard !normalized.isEmpty else { return false }
        return commandSegments(from: normalized).allSatisfy { segment in
            !isExcluded(segment)
        }
    }

    private static func normalize(_ command: String) -> String {
        command
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
    }

    private static func matches(pattern: String, command: String) -> Bool {
        let normalizedPattern = normalize(pattern)
        guard !normalizedPattern.isEmpty else { return false }
        return command == normalizedPattern || command.hasPrefix(normalizedPattern + " ")
    }

    private static func isExcluded(_ command: String) -> Bool {
        SessionRestorePreferences.excludedCommands.contains { pattern in
            matches(pattern: pattern, command: command)
        }
    }

    private static func commandSegments(from command: String) -> [String] {
        ShellSegmentParser.segments(from: command).map(normalize).filter { !$0.isEmpty }
    }
}

private enum ShellSegmentParser {
    static func segments(from command: String) -> [String] {
        var segments: [String] = []
        var current = ""
        var quote: Character?
        var isEscaped = false

        for character in command {
            if isEscaped {
                current.append(character)
                isEscaped = false
                continue
            }
            if character == "\\" {
                isEscaped = true
                continue
            }
            if let activeQuote = quote {
                if character == activeQuote {
                    quote = nil
                } else {
                    current.append(character)
                }
                continue
            }
            if character == "'" || character == "\"" {
                quote = character
                continue
            }
            if character == ";" || character == "|" || character == "&" {
                let segment = current.trimmingCharacters(in: .whitespaces)
                if !segment.isEmpty { segments.append(segment) }
                current = ""
                continue
            }
            current.append(character)
        }

        if isEscaped { current.append("\\") }
        let last = current.trimmingCharacters(in: .whitespaces)
        if !last.isEmpty { segments.append(last) }
        return segments
    }
}
