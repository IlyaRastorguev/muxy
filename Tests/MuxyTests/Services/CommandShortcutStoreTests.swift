import Foundation
import Testing

@testable import Muxy

@Suite("CommandShortcutStore")
@MainActor
struct CommandShortcutStoreTests {
    @Test("addShortcut persists command shortcut")
    func addShortcut() {
        let persistence = InMemoryCommandShortcutPersistence()
        let store = CommandShortcutStore(persistence: persistence)

        let shortcut = store.addShortcut()

        #expect(store.shortcuts.count == 1)
        #expect(persistence.savedConfiguration?.shortcuts == [shortcut])
    }

    @Test("updateShortcut persists changes")
    func updateShortcut() {
        let shortcut = CommandShortcut(name: "Server", command: "npm run dev")
        let persistence = InMemoryCommandShortcutPersistence(shortcuts: [shortcut])
        let store = CommandShortcutStore(persistence: persistence)
        var updated = shortcut
        updated.name = "Tests"
        updated.command = "swift test"

        store.updateShortcut(updated)

        #expect(store.shortcuts == [updated])
        #expect(persistence.savedConfiguration?.shortcuts == [updated])
    }

    @Test("deleteShortcut removes shortcut")
    func deleteShortcut() {
        let shortcut = CommandShortcut(name: "Server", command: "npm run dev")
        let persistence = InMemoryCommandShortcutPersistence(shortcuts: [shortcut])
        let store = CommandShortcutStore(persistence: persistence)

        store.deleteShortcut(id: shortcut.id)

        #expect(store.shortcuts.isEmpty)
        #expect(persistence.savedConfiguration?.shortcuts.isEmpty == true)
    }

    @Test("updatePrefixCombo persists layer shortcut")
    func updatePrefixCombo() {
        let prefix = KeyCombo(key: "j", command: true, shift: true)
        let persistence = InMemoryCommandShortcutPersistence()
        let store = CommandShortcutStore(persistence: persistence)

        store.updatePrefixCombo(prefix)

        #expect(store.prefixCombo == prefix)
        #expect(persistence.savedConfiguration?.prefixCombo == prefix)
    }
}

private final class InMemoryCommandShortcutPersistence: CommandShortcutPersisting {
    var configuration: CommandShortcutConfiguration
    var savedConfiguration: CommandShortcutConfiguration?

    init(
        prefixCombo: KeyCombo = CommandShortcutConfiguration().prefixCombo,
        shortcuts: [CommandShortcut] = []
    ) {
        configuration = CommandShortcutConfiguration(prefixCombo: prefixCombo, shortcuts: shortcuts)
    }

    func loadConfiguration() throws -> CommandShortcutConfiguration {
        configuration
    }

    func saveConfiguration(_ configuration: CommandShortcutConfiguration) throws {
        savedConfiguration = configuration
    }
}
