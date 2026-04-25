import Testing
@testable import Muxy

struct AppAppearancePreferencesTests {
    @Test func clampsTransparencyLevel() {
        #expect(AppAppearancePreferences.clampedTransparencyLevel(-10) == 0)
        #expect(AppAppearancePreferences.clampedTransparencyLevel(42) == 42)
        #expect(AppAppearancePreferences.clampedTransparencyLevel(120) == 100)
    }

    @Test func clampsBlurRadius() {
        #expect(AppAppearancePreferences.clampedBlurRadius(-4) == 0)
        #expect(AppAppearancePreferences.clampedBlurRadius(24) == 24)
        #expect(AppAppearancePreferences.clampedBlurRadius(90) == 64)
    }

    @Test func formatsGhosttyConfigValues() {
        #expect(AppAppearancePreferences.opacityConfigValue(for: 100, blurRadius: 0) == "1.00")
        #expect(AppAppearancePreferences.opacityConfigValue(for: 25) == "0.25")
        #expect(AppAppearancePreferences.blurConfigValue(for: 0) == "false")
        #expect(AppAppearancePreferences.blurConfigValue(for: 12.6) == "13")
    }

    @Test func blurMakesOpaqueBackgroundSlightlyTranslucent() {
        #expect(AppAppearancePreferences.effectiveBackgroundOpacity(transparencyLevel: 100, blurRadius: 0) == 1)
        #expect(AppAppearancePreferences.effectiveBackgroundOpacity(transparencyLevel: 100, blurRadius: 20) == 0.85)
        #expect(AppAppearancePreferences.effectiveBackgroundOpacity(transparencyLevel: 40, blurRadius: 20) == 0.4)
    }
}
