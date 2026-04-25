import Foundation

enum ProjectColorGenerationPreferences {
    static let automaticNewProjectColorsKey = "muxy.appearance.automaticNewProjectColors"

    static func automaticNewProjectColors(defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: automaticNewProjectColorsKey)
    }
}
