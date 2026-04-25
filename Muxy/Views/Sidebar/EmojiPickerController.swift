import AppKit

@MainActor
final class EmojiPickerController {
    static let shared = EmojiPickerController()

    private let window: EmojiPickerWindow
    private let textView: EmojiPickerTextView
    private var onSelect: ((String) -> Void)?

    private init() {
        textView = EmojiPickerTextView()
        window = EmojiPickerWindow(
            contentRect: NSRect(x: -10000, y: -10000, width: 1, height: 1),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        textView.onSelect = { [weak self] emoji in
            let handler = self?.onSelect
            self?.onSelect = nil
            handler?(emoji)
        }
        textView.drawsBackground = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = false
        textView.insertionPointColor = .clear
        textView.frame = NSRect(x: 0, y: 0, width: 1, height: 1)
        window.contentView = textView
        window.backgroundColor = .clear
        window.isOpaque = false
        window.alphaValue = 0.01
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .transient]
    }

    func prepare() {
        window.orderFrontRegardless()
        window.makeFirstResponder(textView)
        window.orderOut(nil)
    }

    func pick(onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            window.orderFrontRegardless()
            window.makeKey()
            window.makeFirstResponder(textView)
            textView.string = ""
            textView.inputContext?.activate()
            if !NSApp.isActive { NSApp.activate(ignoringOtherApps: true) }
            NSApp.orderFrontCharacterPalette(textView)
        }
    }
}

private final class EmojiPickerWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

private final class EmojiPickerTextView: NSTextView {
    var onSelect: ((String) -> Void)?

    override func insertText(_ insertString: Any) {
        accept(insertString)
    }

    override func insertText(_ insertString: Any, replacementRange: NSRange) {
        accept(insertString)
    }

    private func accept(_ insertString: Any) {
        let text: String? = if let string = insertString as? String {
            string
        } else if let attributedString = insertString as? NSAttributedString {
            attributedString.string
        } else {
            nil
        }

        guard let emoji = text?.first.map(String.init) else { return }
        string = ""
        onSelect?(emoji)
    }
}
