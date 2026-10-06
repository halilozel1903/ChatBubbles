import SwiftUI

/// The bar at the bottom of a chat: an attachment button, a text field that grows to six lines, and
/// a send button that is only enabled when there is something to send.
///
/// On the Mac, Return sends and Option-Return starts a new line. On iPhone and iPad, Return starts a
/// new line and the button sends.
///
/// ```swift
/// @State private var draft = ""
///
/// ChatView(messages: messages, currentUserID: "me")
///     .safeAreaInset(edge: .bottom, spacing: 0) {
///         ChatInputBar(text: $draft, onAttach: { showsPhotoPicker = true }) { text in
///             model.send(text)
///         }
///     }
/// ```
public struct ChatInputBar: View {
    @Binding private var text: String
    private let placeholder: String
    private let sendsOnReturn: Bool
    private let onAttach: (() -> Void)?
    private let onSend: (String) -> Void

    @FocusState private var isFocused: Bool
    @Environment(\.chatTheme) private var theme

    /// - Parameters:
    ///   - text: The draft. Cleared after sending.
    ///   - placeholder: Shown while the draft is empty.
    ///   - sendsOnReturn: Whether Return sends; `nil` for the platform default (the Mac only).
    ///   - onAttach: Called by the attachment button; the button is hidden when `nil`.
    ///   - onSend: Called with the draft, trimmed of surrounding spaces and blank lines.
    public init(
        text: Binding<String>,
        placeholder: String = "Message",
        sendsOnReturn: Bool? = nil,
        onAttach: (() -> Void)? = nil,
        onSend: @escaping (String) -> Void
    ) {
        _text = text
        self.placeholder = placeholder
        #if os(macOS)
        self.sendsOnReturn = sendsOnReturn ?? true
        #else
        self.sendsOnReturn = sendsOnReturn ?? false
        #endif
        self.onAttach = onAttach
        self.onSend = onSend
    }

    private var canSend: Bool {
        ChatComposer.sendableText(from: text) != nil
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if let onAttach {
                Button(action: onAttach) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 34, height: 34)
                        .background(Color.secondary.opacity(0.14), in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("Add attachment"))
            }

            HStack(alignment: .bottom, spacing: 6) {
                TextField(placeholder, text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(theme.font)
                    .lineLimit(1...6)
                    .focused($isFocused)
                    .padding(.vertical, 7)
                    .modifier(ReturnToSend(isEnabled: sendsOnReturn, send: { send() }))

                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(canSend ? theme.accent : Color.secondary.opacity(0.5))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .padding(.bottom, 2)
                .accessibilityLabel(Text("Send"))
            }
            .padding(.leading, 14)
            .padding(.trailing, 3)
            .padding(.vertical, 1)
            .background(theme.inputBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func send() {
        guard let message = ChatComposer.sendableText(from: text) else { return }
        onSend(message)
        text = ""
    }
}

/// Sends on Return; Option-Return and Shift-Return are left to the text field (a new line).
private struct ReturnToSend: ViewModifier {
    let isEnabled: Bool
    let send: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.onKeyPress(.return, phases: .down) { press in
                if press.modifiers.contains(.option) || press.modifiers.contains(.shift) {
                    return .ignored
                }
                send()
                return .handled
            }
        } else {
            content
        }
    }
}
