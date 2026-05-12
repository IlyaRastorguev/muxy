import Foundation

@MainActor
final class TerminalCommandTracker {
    static let shared = TerminalCommandTracker()

    private var buffers: [UUID: String] = [:]
    private var lastSubmittedCommands: [UUID: String] = [:]

    private init() {}

    func recordText(_ text: String, paneID: UUID) {
        for character in text {
            switch character {
            case "\n",
                 "\r":
                submitBuffer(paneID: paneID)
            case "\u{7F}",
                 "\u{8}":
                removeLastCharacter(paneID: paneID)
            default:
                buffers[paneID, default: ""].append(character)
            }
        }
    }

    func recordReturn(paneID: UUID) {
        submitBuffer(paneID: paneID)
    }

    func recordBackspace(paneID: UUID) {
        removeLastCharacter(paneID: paneID)
    }

    func lastSubmittedCommand(for paneID: UUID) -> String? {
        lastSubmittedCommands[paneID]
    }

    func removePane(_ paneID: UUID) {
        buffers.removeValue(forKey: paneID)
        lastSubmittedCommands.removeValue(forKey: paneID)
    }

    private func submitBuffer(paneID: UUID) {
        let command = buffers[paneID, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
        buffers[paneID] = ""
        guard !command.isEmpty else { return }
        lastSubmittedCommands[paneID] = command
    }

    private func removeLastCharacter(paneID: UUID) {
        guard var buffer = buffers[paneID], !buffer.isEmpty else { return }
        buffer.removeLast()
        buffers[paneID] = buffer
    }
}
