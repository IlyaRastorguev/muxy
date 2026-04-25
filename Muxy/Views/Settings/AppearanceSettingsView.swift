import SwiftUI

struct AppearanceSettingsView: View {
    @State private var themeService = ThemeService.shared
    @State private var showThemePicker = false
    @State private var currentTheme: String?
    @AppStorage("muxy.vcsDisplayMode") private var vcsDisplayMode = VCSDisplayMode.attached.rawValue
    @AppStorage(AppAppearancePreferences.transparencyLevelKey)
    private var transparencyLevel = AppAppearancePreferences.defaultTransparencyLevel
    @AppStorage(AppAppearancePreferences.blurRadiusKey)
    private var blurRadius = AppAppearancePreferences.defaultBlurRadius

    var body: some View {
        SettingsContainer {
            SettingsSection("Terminal") {
                SettingsRow("Theme") {
                    Button {
                        showThemePicker.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Text(currentTheme ?? "Default")
                                .font(.system(size: SettingsMetrics.labelFontSize))
                                .lineLimit(1)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 10))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showThemePicker) {
                        ThemePicker()
                            .environment(themeService)
                    }
                }

                SettingsSliderRow(
                    label: "Transparency",
                    value: $transparencyLevel,
                    range: AppAppearancePreferences.transparencyRange,
                    unit: "%"
                )

                SettingsSliderRow(
                    label: "Blur",
                    value: $blurRadius,
                    range: AppAppearancePreferences.blurRadiusRange,
                    unit: "px"
                )
            }

            SettingsSection("Source Control", showsDivider: false) {
                SettingsRow("Display Mode") {
                    Picker("", selection: $vcsDisplayMode) {
                        ForEach(VCSDisplayMode.allCases) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: SettingsMetrics.controlWidth)
                }
            }
        }
        .task {
            currentTheme = themeService.currentThemeName()
        }
        .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { _ in
            currentTheme = themeService.currentThemeName()
        }
        .onChange(of: transparencyLevel) {
            transparencyLevel = AppAppearancePreferences.clampedTransparencyLevel(transparencyLevel)
            AppAppearancePreferences.applyToGhosttyConfig()
        }
        .onChange(of: blurRadius) {
            blurRadius = AppAppearancePreferences.clampedBlurRadius(blurRadius)
            AppAppearancePreferences.applyToGhosttyConfig()
        }
    }
}

private struct SettingsSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        SettingsRow(label) {
            HStack(spacing: 8) {
                Slider(value: $value, in: range)
                    .frame(width: 150)
                Text(displayValue)
                    .font(.system(size: SettingsMetrics.labelFontSize, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 46, alignment: .trailing)
            }
            .frame(width: SettingsMetrics.controlWidth, alignment: .trailing)
        }
    }

    private var displayValue: String {
        "\(Int(value.rounded()))\(unit)"
    }
}
