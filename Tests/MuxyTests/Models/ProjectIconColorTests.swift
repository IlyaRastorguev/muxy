import MuxyShared
import Testing

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
}
