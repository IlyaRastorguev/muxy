import Foundation
import Testing

@testable import Muxy

@Suite("ProjectStore")
@MainActor
struct ProjectStoreTests {
    @Test("setIcon updates project emoji and persists")
    func setIconPersistsEmoji() {
        let project = Project(name: "Muxy", path: "/tmp/muxy")
        let persistence = StubProjectPersistence(projects: [project])
        let store = ProjectStore(persistence: persistence)

        store.setIcon(id: project.id, to: "🚀")

        #expect(store.projects.first?.icon == "🚀")
        #expect(persistence.savedProjects.last?.first?.icon == "🚀")
    }

    @Test("setIcon clears project emoji and persists")
    func setIconClearsEmoji() {
        var project = Project(name: "Muxy", path: "/tmp/muxy")
        project.icon = "🚀"
        let persistence = StubProjectPersistence(projects: [project])
        let store = ProjectStore(persistence: persistence)

        store.setIcon(id: project.id, to: nil)

        #expect(store.projects.first?.icon == nil)
        #expect(persistence.savedProjects.last?.first?.icon == nil)
    }
}

private final class StubProjectPersistence: ProjectPersisting {
    private let loadedProjects: [Project]
    private(set) var savedProjects: [[Project]] = []

    init(projects: [Project]) {
        loadedProjects = projects
    }

    func loadProjects() throws -> [Project] {
        loadedProjects
    }

    func saveProjects(_ projects: [Project]) throws {
        savedProjects.append(projects)
    }
}
