import SwiftUI

/// One message in a bubble: an optional reply quote, an optional image and the text with Markdown
/// and links.
///
/// ``ChatView`` places bubbles for you. Use `MessageBubble` on its own for custom layouts:
///
/// ```swift
/// MessageBubble(message: message, isOutgoing: true, position: .last)
/// ```
public struct MessageBubble<Message: ChatMessage>: View {
    private let message: Message
    private let isOutgoing: Bool
    private let position: BubblePosition

    @Environment(\.chatTheme) private var theme

    /// - Parameters:
    ///   - message: The message to show.
    ///   - isOutgoing: Sent by the current user: trailing side, outgoing colors.
    ///   - position: The bubble's place in its group; decides the corners and the tail.
    public init(message: Message, isOutgoing: Bool, position: BubblePosition = .single) {
        self.message = message
        self.isOutgoing = isOutgoing
        self.position = position
    }

    public var body: some View {
        let foreground = isOutgoing ? theme.outgoingForeground : theme.incomingForeground
        let background = isOutgoing ? theme.outgoingBackground : theme.incomingBackground
        let shape = BubbleShape(
            position: position,
            isOutgoing: isOutgoing,
            radius: theme.cornerRadius,
            groupedRadius: theme.groupedCornerRadius,
            showsTail: theme.showsTails,
            tailWidth: theme.tailWidth
        )
        let hasText = !message.text.isEmpty

        VStack(alignment: .leading, spacing: 0) {
            if let reply = message.reply {
                ReplyQuote(reply: reply, isOutgoing: isOutgoing)
                    .padding(.horizontal, 6)
                    .padding(.top, 6)
                    .padding(.bottom, hasText || message.attachment != nil ? 0 : 6)
            }
            if let attachment = message.attachment {
                AttachmentImage(attachment: attachment)
                    .clipShape(RoundedRectangle(cornerRadius: max(theme.cornerRadius - 4, 4), style: .continuous))
                    .padding(4)
            }
            if hasText {
                Text(Self.styledText(message.text))
                    .font(theme.font)
                    .foregroundStyle(foreground)
                    .tint(isOutgoing ? foreground : theme.accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.top, message.attachment == nil ? 8 : 2)
                    .padding(.bottom, 8)
            }
        }
        .padding(isOutgoing ? .trailing : .leading, theme.tailWidth)
        .background(shape.fill(background))
        .contentShape(shape)
        .accessibilityElement(children: .combine)
    }

    /// The message text with links underlined, so they stand out in a colored bubble too.
    private static func styledText(_ text: String) -> AttributedString {
        var string = MessageText.attributedString(from: text)
        for run in string.runs where run[AttributeScopes.FoundationAttributes.LinkAttribute.self] != nil {
            string[run.range][AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] = .single
        }
        return string
    }
}

/// The quoted message at the top of a reply.
public struct ReplyQuote: View {
    private let reply: ChatReply
    private let isOutgoing: Bool

    @Environment(\.chatTheme) private var theme

    public init(reply: ChatReply, isOutgoing: Bool) {
        self.reply = reply
        self.isOutgoing = isOutgoing
    }

    public var body: some View {
        let foreground = isOutgoing ? theme.outgoingForeground : theme.incomingForeground
        VStack(alignment: .leading, spacing: 1) {
            Text(reply.senderName)
                .font(.caption.weight(.semibold))
            Text(reply.text)
                .font(.caption)
                .lineLimit(2)
                .opacity(0.85)
        }
        .foregroundStyle(foreground)
        .padding(.leading, 13)
        .padding(.trailing, 10)
        .padding(.vertical, 6)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(isOutgoing ? foreground : theme.accent)
                .frame(width: 3)
                .padding(.vertical, 6)
                .padding(.leading, 5)
        }
        .background(foreground.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Reply to \(reply.senderName): \(reply.text)"))
    }
}

/// The image of a ``ChatAttachment``, in its aspect ratio.
struct AttachmentImage: View {
    let attachment: ChatAttachment
    var maximumWidth: CGFloat = 260

    var body: some View {
        Color.clear
            .aspectRatio(CGFloat(attachment.aspectRatio), contentMode: .fit)
            .frame(maxWidth: maximumWidth)
            .overlay {
                switch attachment {
                case .image(let name, _, _):
                    Image(name)
                        .resizable()
                        .scaledToFill()
                case .remoteImage(let url, _, _):
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Color.secondary.opacity(0.15)
                                .overlay {
                                    if phase.error != nil {
                                        Image(systemName: "photo")
                                            .foregroundStyle(.secondary)
                                    } else {
                                        ProgressView()
                                    }
                                }
                        }
                    }
                }
            }
            .clipped()
            .accessibilityElement()
            .accessibilityLabel(Text(attachment.accessibilityDescription))
            .accessibilityAddTraits(.isImage)
    }
}
