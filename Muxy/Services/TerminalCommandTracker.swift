import Foundation
import GhosttyKit

@MainActor
final class TerminalCommandTracker {
    static let shared = TerminalCommandTracker()

    private var buffers: [UUID: String] = [:]
    private var pendingCommands: [UUID: String] = [:]
    private var confirmedCommands: [UUID: String] = [:]
    private var secureInputPanes: Set<UUID> = []

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

    func confirmCommand(paneID: UUID) {
        guard let pending = pendingCommands[paneID] else { return }
        confirmedCommands[paneID] = pending
        pendingCommands.removeValue(forKey: paneID)
    }

    func setSecureInput(_ action: ghostty_action_secure_input_e, paneID: UUID) {
        switch action {
        case GHOSTTY_SECURE_INPUT_ON:
            secureInputPanes.insert(paneID)
        case GHOSTTY_SECURE_INPUT_OFF:
            secureInputPanes.remove(paneID)
        case GHOSTTY_SECURE_INPUT_TOGGLE:
            if secureInputPanes.contains(paneID) {
                secureInputPanes.remove(paneID)
            } else {
                secureInputPanes.insert(paneID)
            }
        default:
            break
        }
    }

    func lastSubmittedCommand(for paneID: UUID) -> String? {
        confirmedCommands[paneID] ?? pendingCommands[paneID]
    }

    func clearBuffer(paneID: UUID) {
        buffers[paneID] = ""
    }

    func removePane(_ paneID: UUID) {
        buffers.removeValue(forKey: paneID)
        pendingCommands.removeValue(forKey: paneID)
        confirmedCommands.removeValue(forKey: paneID)
        secureInputPanes.remove(paneID)
    }

    private func submitBuffer(paneID: UUID) {
        guard !secureInputPanes.contains(paneID) else {
            buffers[paneID] = ""
            return
        }
        let command = buffers[paneID, default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
        buffers[paneID] = ""
        guard !command.isEmpty else { return }
        pendingCommands[paneID] = command
    }

    private func removeLastCharacter(paneID: UUID) {
        guard !(buffers[paneID]?.isEmpty ?? true) else { return }
        buffers[paneID]?.removeLast()
    }
}
