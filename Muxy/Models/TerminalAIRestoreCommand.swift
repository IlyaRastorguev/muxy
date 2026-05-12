import Foundation

enum TerminalAIRestoreCommand {
    static func rewriting(_ command: String) -> String {
        let normalized = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return command }
        guard !containsShellSeparator(normalized) else { return command }
        let tokens = ShellCommandTokenizer.tokens(from: normalized)
        guard let executable = tokens.first else { return command }

        switch executableName(from: executable) {
        case "codex":
            return codexCommand(from: tokens) ?? command
        case "claude":
            return continuationCommand(from: tokens, flag: "--continue") ?? command
        case "agent":
            return continuationCommand(from: tokens, flag: "--continue") ?? command
        case "opencode":
            return continuationCommand(from: tokens, flag: "--continue") ?? command
        default:
            return command
        }
    }

    private static func codexCommand(from tokens: [String]) -> String? {
        guard !tokens.dropFirst().contains("resume") else { return nil }
        return shellCommand([tokens[0], "resume", "--last"] + tokens.dropFirst())
    }

    private static func continuationCommand(from tokens: [String], flag: String) -> String? {
        let arguments = tokens.dropFirst()
        guard !arguments.contains(flag) else { return nil }
        guard !arguments.contains("--resume") else { return nil }
        guard !arguments.contains("resume") else { return nil }
        return shellCommand([tokens[0], flag] + arguments)
    }

    private static func executableName(from executable: String) -> String {
        (executable as NSString).lastPathComponent
    }

    private static func shellCommand(_ tokens: [String]) -> String {
        tokens.map(ShellEscaper.escape).joined(separator: " ")
    }

    private static func containsShellSeparator(_ command: String) -> Bool {
        var isEscaped = false
        var quote: Character?
        for character in command {
            if isEscaped {
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
                }
                continue
            }
            if character == "'" || character == "\"" {
                quote = character
                continue
            }
            if character == ";" || character == "|" || character == "&" {
                return true
            }
        }
        return false
    }
}

private enum ShellCommandTokenizer {
    static func tokens(from command: String) -> [String] {
        var tokens: [String] = []
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
            if character.isWhitespace {
                appendToken(&tokens, current: &current)
                continue
            }
            current.append(character)
        }

        if isEscaped {
            current.append("\\")
        }
        appendToken(&tokens, current: &current)
        return tokens
    }

    private static func appendToken(_ tokens: inout [String], current: inout String) {
        guard !current.isEmpty else { return }
        tokens.append(current)
        current = ""
    }
}
