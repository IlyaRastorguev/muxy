import MuxyShared
import SwiftUI
import Testing

@testable import Muxy

@Suite("ProjectIconColor")
struct ProjectIconColorTests {
    @Test("generated color is stable and valid hex")
    func generatedColorIsStableAndValidHex() {
        let color = ProjectIconColor.generatedHex(for: "Muxy")

        #expect(color == ProjectIconColor.generatedHex(for: "Muxy"))
        #expect(color.hasPrefix("#"))
        #expect(color.count == 7)
        #expect(ProjectIconColor.rgb(fromHex: color) != nil)
    }

    @Test("generated color normalizes whitespace and case")
    func generatedColorNormalizesWhitespaceAndCase() {
        #expect(ProjectIconColor.generatedHex(for: " Muxy ") == ProjectIconColor.generatedHex(for: "muxy"))
    }

    @Test("different project names generate different colors")
    func differentProjectNamesGenerateDifferentColors() {
        #expect(ProjectIconColor.generatedHex(for: "Muxy") != ProjectIconColor.generatedHex(for: "Ghostty"))
    }

    @Test("empty string uses fallback seed and returns valid hex")
    func emptyStringReturnsFallbackColor() {
        let color = ProjectIconColor.generatedHex(for: "")
        #expect(color.hasPrefix("#"))
        #expect(color.count == 7)
        #expect(ProjectIconColor.rgb(fromHex: color) != nil)
    }

    @Test("color(for:) resolves raw hex identifier")
    func colorForRawHex() {
        let hex = ProjectIconColor.generatedHex(for: "Muxy")
        #expect(ProjectIconColor.color(for: hex) != nil)
        #expect(ProjectIconColor.color(for: nil) == nil)
    }

    @Test("foreground(for:) returns black or white for raw hex")
    func foregroundForRawHex() {
        #expect(ProjectIconColor.foreground(for: "#FFFFFF") == .black)
        #expect(ProjectIconColor.foreground(for: "#000000") == .white)
        #expect(ProjectIconColor.foreground(for: nil) == nil)
        #expect(ProjectIconColor.foreground(for: "not-a-hex") == nil)
    }
}
