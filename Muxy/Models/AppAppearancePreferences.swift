import Foundation

enum AppAppearancePreferences {
    static let transparencyLevelKey = "muxy.appearance.transparencyLevel"
    static let blurRadiusKey = "muxy.appearance.blurRadius"
    static let defaultTransparencyLevel: Double = 100
    static let defaultBlurRadius: Double = 0
    static let transparencyRange: ClosedRange<Double> = 0...100
    static let blurRadiusRange: ClosedRange<Double> = 0...64

    static var transparencyLevel: Double {
        clampedTransparencyLevel(UserDefaults.standard.object(forKey: transparencyLevelKey) as? Double ?? defaultTransparencyLevel)
    }

    static var blurRadius: Double {
        clampedBlurRadius(UserDefaults.standard.object(forKey: blurRadiusKey) as? Double ?? defaultBlurRadius)
    }

    static var backgroundOpacity: Double {
        effectiveBackgroundOpacity(
            transparencyLevel: transparencyLevel,
            blurRadius: blurRadius
        )
    }

    static func clampedTransparencyLevel(_ value: Double) -> Double {
        min(transparencyRange.upperBound, max(transparencyRange.lowerBound, value))
    }

    static func clampedBlurRadius(_ value: Double) -> Double {
        min(blurRadiusRange.upperBound, max(blurRadiusRange.lowerBound, value))
    }

    static func effectiveBackgroundOpacity(transparencyLevel: Double, blurRadius: Double) -> Double {
        let opacity = clampedTransparencyLevel(transparencyLevel) / 100
        guard clampedBlurRadius(blurRadius) > 0 else { return opacity }
        return min(opacity, 0.85)
    }

    static func opacityConfigValue(for transparencyLevel: Double, blurRadius: Double = Self.blurRadius) -> String {
        let opacity = effectiveBackgroundOpacity(
            transparencyLevel: transparencyLevel,
            blurRadius: blurRadius
        )
        return String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), opacity)
    }

    static func blurConfigValue(for blurRadius: Double) -> String {
        let blur = Int(clampedBlurRadius(blurRadius).rounded())
        guard blur > 0 else { return "false" }
        return String(blur)
    }

    @MainActor
    static func writeGhosttyConfig(
        transparencyLevel: Double = Self.transparencyLevel,
        blurRadius: Double = Self.blurRadius,
        config: MuxyConfig = .shared
    ) {
        config.updateConfigValue("background-opacity", value: opacityConfigValue(
            for: transparencyLevel,
            blurRadius: blurRadius
        ))
        config.updateConfigValue("background-blur", value: blurConfigValue(for: blurRadius))
        config.removeConfigValue("background-blur-radius")
    }

    @MainActor
    static func applyToGhosttyConfig(
        transparencyLevel: Double = Self.transparencyLevel,
        blurRadius: Double = Self.blurRadius,
        config: MuxyConfig = .shared,
        ghostty: GhosttyService = .shared
    ) {
        writeGhosttyConfig(
            transparencyLevel: transparencyLevel,
            blurRadius: blurRadius,
            config: config
        )
        ghostty.reloadConfig()
    }
}
