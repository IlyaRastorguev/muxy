import SwiftUI

private enum TerminalOmniboxQuickFilter: Equatable {
    case commands
    case history
    case openTabs
}

struct TerminalOmniboxOverlay: View {
    let projects: [TerminalOmniboxProjectItem]
    let worktrees: [TerminalOmniboxWorktreeItem]
    let openTabs: [OpenTerminalTabItem]
    let closedTabs: [ClosedTerminalTabSnapshot]
    let commandShortcuts: [CommandShortcut]
    let activeProjectID: UUID?
    let activeWorktreeID: UUID?
    let commandProjectIDs: Set<UUID>
    let onSelect: (TerminalOmniboxItem, UUID?, UUID?) -> Void
    let onDismiss: () -> Void

    @State private var query = ""
    @State private var highlightedIndex: Int? = 0
    @State private var scopedProjectID: UUID?
    @State private var scopedWorktreeID: UUID?
    @State private var quickFilter: TerminalOmniboxQuickFilter?

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var scopedProject: TerminalOmniboxProjectItem? {
        guard let scopedProjectID else { return nil }
        return projects.first { $0.projectID == scopedProjectID }
    }

    private var scopedWorktree: TerminalOmniboxWorktreeItem? {
        guard let scopedWorktreeID else { return nil }
        return worktrees.first { $0.worktreeID == scopedWorktreeID }
    }

    private var scopedCanCreateCommand: Bool {
        guard let scopedProjectID, scopedWorktreeID != nil else { return false }
        return commandProjectIDs.contains(scopedProjectID)
    }

    private var displayList: [TerminalOmniboxItem] {
        var items = baseItems
        if quickFilter == nil, scopedCanCreateCommand, !trimmedQuery.isEmpty {
            let typed = TerminalOmniboxItem.typedCommand(trimmedQuery)
            if !items.contains(typed) {
                items.append(typed)
            }
        }
        return items
    }

    private var baseItems: [TerminalOmniboxItem] {
        if let quickFilter {
            return filteredScopedItems(quickFilter)
        }
        if scopedProjectID != nil, scopedWorktreeID != nil {
            return allScopedItems()
        }
        if let scopedProjectID {
            let scopedWorktrees = worktrees
                .filter { $0.projectID == scopedProjectID }
            guard !trimmedQuery.isEmpty else {
                return scopedWorktrees.map(TerminalOmniboxItem.worktree)
            }
            return scopedWorktrees
                .filter { $0.searchKey.localizedCaseInsensitiveContains(trimmedQuery) }
                .map(TerminalOmniboxItem.worktree)
        }
        return projectItems
    }

    private var projectItems: [TerminalOmniboxItem] {
        let source = trimmedQuery.isEmpty && scopedProjectID != nil ? [] : projects
        return source
            .filter { trimmedQuery.isEmpty || $0.searchKey.localizedCaseInsensitiveContains(trimmedQuery) }
            .map(TerminalOmniboxItem.project)
    }

    private func allScopedItems() -> [TerminalOmniboxItem] {
        guard let scopedProjectID, let scopedWorktreeID else { return [] }
        var items = openTabs
            .filter { $0.projectID == scopedProjectID && $0.worktreeID == scopedWorktreeID }
            .map(TerminalOmniboxItem.openTab)
            + closedTabs
            .filter { $0.projectID == scopedProjectID && $0.worktreeID == scopedWorktreeID }
            .map(TerminalOmniboxItem.closedTab)
        if commandProjectIDs.contains(scopedProjectID) {
            items += commandShortcuts
                .filter { !$0.trimmedCommand.isEmpty }
                .map(TerminalOmniboxItem.commandShortcut)
        }
        guard !trimmedQuery.isEmpty else { return items }
        return items.filter { $0.searchKey.localizedCaseInsensitiveContains(trimmedQuery) }
    }

    private func filteredScopedItems(_ filter: TerminalOmniboxQuickFilter) -> [TerminalOmniboxItem] {
        guard let scopedProjectID, let scopedWorktreeID else { return [] }
        let items: [TerminalOmniboxItem]
        switch filter {
        case .commands:
            guard commandProjectIDs.contains(scopedProjectID) else { return [] }
            items = commandShortcuts
                .filter { !$0.trimmedCommand.isEmpty }
                .map(TerminalOmniboxItem.commandShortcut)
        case .history:
            items = closedTabs
                .filter { $0.projectID == scopedProjectID && $0.worktreeID == scopedWorktreeID }
                .map(TerminalOmniboxItem.closedTab)
        case .openTabs:
            items = openTabs
                .filter { $0.projectID == scopedProjectID && $0.worktreeID == scopedWorktreeID }
                .map(TerminalOmniboxItem.openTab)
        }
        guard !trimmedQuery.isEmpty else { return items }
        return items.filter { $0.searchKey.localizedCaseInsensitiveContains(trimmedQuery) }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            OverlayPanel(width: UIMetrics.scaled(720), height: UIMetrics.scaled(460)) {
                VStack(spacing: 0) {
                    searchField
                    Divider().overlay(MuxyTheme.border)
                    resultsList
                    Divider().overlay(MuxyTheme.border)
                    footer
                }
            }
        }
        .onAppear {
            scopedProjectID = activeProjectID
            scopedWorktreeID = activeProjectID != nil ? activeWorktreeID : nil
            highlightedIndex = displayList.isEmpty ? nil : 0
        }
        .onChange(of: query) {
            highlightedIndex = displayList.isEmpty ? nil : 0
        }
        .onChange(of: scopedProjectID) {
            quickFilter = nil
            highlightedIndex = displayList.isEmpty ? nil : 0
        }
        .onChange(of: scopedWorktreeID) {
            quickFilter = nil
            highlightedIndex = displayList.isEmpty ? nil : 0
        }
        .onChange(of: quickFilter) {
            highlightedIndex = displayList.isEmpty ? nil : 0
        }
        .onChange(of: openTabs.count) {
            highlightedIndex = displayList.isEmpty ? nil : min(highlightedIndex ?? 0, displayList.count - 1)
        }
        .onChange(of: closedTabs.count) {
            highlightedIndex = displayList.isEmpty ? nil : min(highlightedIndex ?? 0, displayList.count - 1)
        }
    }

    private var searchField: some View {
        HStack(spacing: UIMetrics.spacing4) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: UIMetrics.fontEmphasis, weight: .semibold))
                .foregroundStyle(MuxyTheme.fgMuted)
                .accessibilityHidden(true)
            if let scopedProject {
                scopedProjectChip(scopedProject)
            }
            if let scopedWorktree {
                scopedWorktreeChip(scopedWorktree)
            }
            PaletteSearchField(
                text: $query,
                placeholder: searchPlaceholder,
                onSubmit: { confirmSelection() },
                onEscape: { onDismiss() },
                onArrowUp: { moveHighlight(-1) },
                onArrowDown: { moveHighlight(1) },
                onTab: { handleTab() },
                onBackTab: { handleBackTab() },
                onEmptyBackspace: { handleEmptyBackspace() },
                onOptionCommandKey: { handleOptionKey($0) }
            )
            .frame(height: UIMetrics.scaled(28))
            quickFilterControls
        }
        .frame(height: UIMetrics.scaled(28))
        .padding(.horizontal, UIMetrics.spacing6)
        .padding(.vertical, UIMetrics.spacing5)
    }

    private var quickFilterControls: some View {
        HStack(spacing: UIMetrics.spacing2) {
            TerminalOmniboxFilterButton(
                symbol: "folder",
                isActive: scopedProjectID == nil && quickFilter == nil,
                help: "⌥⌘P Project"
            ) {
                activateProjectSelection()
            }
            TerminalOmniboxFilterButton(
                symbol: "arrow.triangle.branch",
                isActive: scopedProjectID != nil && scopedWorktreeID == nil && quickFilter == nil,
                help: "⌥⌘W Worktree"
            ) {
                activateWorktreeSelection()
            }
            TerminalOmniboxFilterButton(
                symbol: "command",
                isActive: quickFilter == .commands,
                help: "⌥⌘C Commands"
            ) {
                toggleQuickFilter(.commands)
            }
            TerminalOmniboxFilterButton(
                symbol: "clock.arrow.circlepath",
                isActive: quickFilter == .history,
                help: "⌥⌘H History"
            ) {
                toggleQuickFilter(.history)
            }
            TerminalOmniboxFilterButton(
                symbol: "terminal",
                isActive: quickFilter == .openTabs,
                help: "⌥⌘T Open Tabs"
            ) {
                toggleQuickFilter(.openTabs)
            }
        }
    }

    private var searchPlaceholder: String {
        if let quickFilter {
            return quickFilterPlaceholder(quickFilter)
        }
        if scopedProject == nil {
            return "Search project..."
        }
        if scopedWorktree == nil {
            return "Search worktree..."
        }
        return "Search tabs, history, or run command..."
    }

    private func quickFilterPlaceholder(_ filter: TerminalOmniboxQuickFilter) -> String {
        switch filter {
        case .commands:
            "Search custom commands..."
        case .history:
            "Search history..."
        case .openTabs:
            "Search open tabs..."
        }
    }

    private func scopedProjectChip(_ project: TerminalOmniboxProjectItem) -> some View {
        Button {
            activateProjectSelection()
        } label: {
            HStack(spacing: UIMetrics.scaled(5)) {
                Image(systemName: "folder")
                    .font(.system(size: UIMetrics.fontXS, weight: .semibold))
                Text(project.name)
                    .font(.system(size: UIMetrics.fontFootnote, weight: .medium))
                    .lineLimit(1)
                if scopedWorktreeID == nil {
                    Image(systemName: "xmark")
                        .font(.system(size: UIMetrics.fontMicro, weight: .bold))
                }
            }
            .foregroundStyle(MuxyTheme.fg)
            .padding(.horizontal, UIMetrics.spacing3)
            .padding(.vertical, UIMetrics.spacing2)
            .background(MuxyTheme.surface, in: Capsule())
            .overlay(Capsule().stroke(MuxyTheme.border, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("Clear project scope")
    }

    private func scopedWorktreeChip(_ worktree: TerminalOmniboxWorktreeItem) -> some View {
        Button {
            activateWorktreeSelection()
        } label: {
            HStack(spacing: UIMetrics.scaled(5)) {
                Image(systemName: worktree.isPrimary ? "folder.badge.gearshape" : "arrow.triangle.branch")
                    .font(.system(size: UIMetrics.fontXS, weight: .semibold))
                Text(worktree.name)
                    .font(.system(size: UIMetrics.fontFootnote, weight: .medium))
                    .lineLimit(1)
                Image(systemName: "xmark")
                    .font(.system(size: UIMetrics.fontMicro, weight: .bold))
            }
            .foregroundStyle(MuxyTheme.fg)
            .padding(.horizontal, UIMetrics.spacing3)
            .padding(.vertical, UIMetrics.spacing2)
            .background(MuxyTheme.surface, in: Capsule())
            .overlay(Capsule().stroke(MuxyTheme.border, lineWidth: 1))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .help("Clear worktree scope")
    }

    private var resultsList: some View {
        Group {
            if displayList.isEmpty {
                VStack {
                    Spacer()
                    Text(emptyStateText)
                        .font(.system(size: UIMetrics.fontBody))
                        .foregroundStyle(MuxyTheme.fgMuted)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(displayList.enumerated()), id: \.element.id) { index, item in
                                if shouldShowSectionHeader(at: index) {
                                    TerminalOmniboxSectionHeader(title: item.sectionTitle)
                                }
                                TerminalOmniboxRow(item: item, isHighlighted: index == highlightedIndex)
                                    .contentShape(Rectangle())
                                    .onTapGesture { handleTap(item) }
                                    .id(item.id)
                            }
                        }
                    }
                    .onChange(of: highlightedIndex) { _, newIndex in
                        guard let newIndex, newIndex < displayList.count else { return }
                        proxy.scrollTo(displayList[newIndex].id, anchor: nil)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: UIMetrics.scaled(18)) {
            TerminalOmniboxHint(symbol: "return", label: returnHintLabel)
            HStack(spacing: UIMetrics.scaled(2)) {
                TerminalOmniboxHint(text: tabHintText)
                TerminalOmniboxHint(symbol: "arrow.up.arrow.down", label: navigateHintLabel)
            }
            HStack(spacing: UIMetrics.scaled(2)) {
                TerminalOmniboxHint(symbol: "option")
                TerminalOmniboxHint(symbol: "command")
                TerminalOmniboxHint(text: "p,w,c,h,t", label: "Change scope")
            }
            TerminalOmniboxHint(text: "Esc", label: "Close")
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, UIMetrics.spacing5)
        .padding(.vertical, UIMetrics.spacing4)
    }

    private var emptyStateText: String {
        if scopedProjectID == nil {
            return "No projects found"
        }
        if scopedWorktreeID == nil {
            return "No worktrees found"
        }
        return "No tabs, history, or commands"
    }

    private var returnHintLabel: String {
        if scopedProjectID == nil { return "Scope Project" }
        if scopedWorktreeID == nil { return "Scope Worktree" }
        return "Open"
    }

    private var tabHintText: String {
        "Tab/⇧Tab"
    }

    private var navigateHintLabel: String {
        "Navigate"
    }

    private func handleTab() {
        moveHighlight(1)
    }

    private func handleBackTab() {
        moveHighlight(-1)
    }

    private func shouldShowSectionHeader(at index: Int) -> Bool {
        guard index < displayList.count else { return false }
        if index == 0 { return true }
        return displayList[index].sectionTitle != displayList[index - 1].sectionTitle
    }

    private func moveHighlight(_ delta: Int) {
        guard !displayList.isEmpty else { return }
        guard let current = highlightedIndex else {
            highlightedIndex = delta > 0 ? 0 : displayList.count - 1
            return
        }
        highlightedIndex = max(0, min(displayList.count - 1, current + delta))
    }

    private func confirmSelection() {
        guard let index = highlightedIndex, index < displayList.count else {
            guard scopedCanCreateCommand, !trimmedQuery.isEmpty else { return }
            onSelect(.typedCommand(trimmedQuery), scopedProjectID, scopedWorktreeID)
            return
        }
        let item = displayList[index]
        switch item {
        case .project:
            scopeHighlightedItem()
        case .worktree:
            scopeHighlightedItem()
        default:
            onSelect(item, scopedProjectID, scopedWorktreeID)
        }
    }

    private func handleTap(_ item: TerminalOmniboxItem) {
        switch item {
        case let .project(project):
            scopedProjectID = project.projectID
            query = ""
        case let .worktree(wt):
            scopedWorktreeID = wt.worktreeID
            query = ""
        default:
            onSelect(item, scopedProjectID, scopedWorktreeID)
        }
    }

    private func scopeHighlightedItem() {
        guard let index = highlightedIndex, index < displayList.count else { return }
        switch displayList[index] {
        case let .project(project):
            scopedProjectID = project.projectID
            query = ""
        case let .worktree(wt):
            scopedWorktreeID = wt.worktreeID
            query = ""
        default:
            break
        }
    }

    private func activateProjectSelection() {
        scopedProjectID = nil
        scopedWorktreeID = nil
        quickFilter = nil
        query = ""
    }

    private func activateWorktreeSelection() {
        guard scopedProjectID != nil else { return }
        scopedWorktreeID = nil
        quickFilter = nil
        query = ""
    }

    private func handleEmptyBackspace() {
        if quickFilter != nil {
            quickFilter = nil
            return
        }
        if scopedWorktreeID != nil {
            activateWorktreeSelection()
            return
        }
        activateProjectSelection()
    }

    private func handleOptionKey(_ key: String) -> Bool {
        switch key {
        case "c":
            toggleQuickFilter(.commands)
        case "h":
            toggleQuickFilter(.history)
        case "t":
            toggleQuickFilter(.openTabs)
        case "p":
            activateProjectSelection()
        case "w":
            activateWorktreeSelection()
        default:
            return false
        }
        return true
    }

    private func toggleQuickFilter(_ filter: TerminalOmniboxQuickFilter) {
        quickFilter = quickFilter == filter ? nil : filter
    }
}

private struct TerminalOmniboxFilterButton: View {
    let symbol: String
    let isActive: Bool
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: UIMetrics.fontFootnote, weight: .semibold))
                .foregroundStyle(isActive ? MuxyTheme.accent : MuxyTheme.fgMuted)
                .frame(width: UIMetrics.controlMedium, height: UIMetrics.controlMedium)
                .background(isActive ? MuxyTheme.accent.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isActive ? MuxyTheme.accent.opacity(0.35) : MuxyTheme.border, lineWidth: 1)
                )
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

private struct TerminalOmniboxSectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: UIMetrics.fontXS, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(MuxyTheme.fgDim)
            Spacer()
        }
        .padding(.horizontal, UIMetrics.spacing6)
        .padding(.top, UIMetrics.spacing4)
        .padding(.bottom, UIMetrics.scaled(3))
    }
}

private struct TerminalOmniboxRow: View {
    let item: TerminalOmniboxItem
    let isHighlighted: Bool
    @State private var hovered = false

    var body: some View {
        HStack(spacing: UIMetrics.spacing5) {
            Image(systemName: item.symbol)
                .font(.system(size: UIMetrics.fontFootnote, weight: .semibold))
                .foregroundStyle(MuxyTheme.fgMuted)
                .frame(width: UIMetrics.iconLG, alignment: .center)
            VStack(alignment: .leading, spacing: UIMetrics.scaled(1)) {
                Text(item.title)
                    .font(.system(size: UIMetrics.fontBody, weight: .medium))
                    .foregroundStyle(MuxyTheme.fg)
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let subtitle = item.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: UIMetrics.fontCaption))
                        .foregroundStyle(MuxyTheme.fgDim)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: UIMetrics.spacing2)
        }
        .frame(height: UIMetrics.scaled(40))
        .padding(.horizontal, UIMetrics.spacing6)
        .background(isHighlighted ? MuxyTheme.surface : hovered ? MuxyTheme.hover : .clear)
        .onHover { hovered = $0 }
    }
}

private struct TerminalOmniboxHint: View {
    var symbol: String?
    var text: String?
    var label: String?

    var body: some View {
        HStack(spacing: UIMetrics.scaled(4)) {
            HStack(spacing: UIMetrics.scaled(3)) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: UIMetrics.fontCaption, weight: .semibold))
                        .foregroundStyle(MuxyTheme.fgMuted)
                }
                if let text {
                    Text(text)
                        .font(.system(size: UIMetrics.fontCaption, weight: .semibold, design: .monospaced))
                        .foregroundStyle(MuxyTheme.fgMuted)
                }
            }
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, UIMetrics.scaled(4))
            .padding(.vertical, UIMetrics.scaled(2))
            .background(MuxyTheme.surface, in: RoundedRectangle(cornerRadius: UIMetrics.radiusSM))
            .overlay(RoundedRectangle(cornerRadius: UIMetrics.radiusSM).stroke(MuxyTheme.border, lineWidth: 1))
            if let label {
                Text(label)
                    .font(.system(size: UIMetrics.fontFootnote, weight: .medium))
                    .foregroundStyle(MuxyTheme.fgDim)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }
}
