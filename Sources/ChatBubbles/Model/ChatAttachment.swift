import Foundation

/// An image attached to a message.
public enum ChatAttachment: Hashable, Sendable {
    /// An image from the app's asset catalog.
    ///
    /// - Parameters:
    ///   - name: The image's name in the main bundle.
    ///   - aspectRatio: Width divided by height; the bubble keeps this shape.
    ///   - description: What the image shows, read by VoiceOver.
    case image(name: String, aspectRatio: Double = 4.0 / 3.0, description: String? = nil)

    /// An image loaded from a URL with `AsyncImage`. A placeholder of the same shape is shown while
    /// it loads.
    case remoteImage(url: URL, aspectRatio: Double = 4.0 / 3.0, description: String? = nil)

    /// Width divided by height.
    public var aspectRatio: Double {
        switch self {
        case .image(_, let aspectRatio, _), .remoteImage(_, let aspectRatio, _):
            aspectRatio > 0 ? aspectRatio : 4.0 / 3.0
        }
    }

    /// The text VoiceOver reads for the image.
    public var accessibilityDescription: String {
        switch self {
        case .image(_, _, let description), .remoteImage(_, _, let description):
            description ?? "Image"
        }
    }
}

/// The message a reply answers, shown as a quote inside the reply's bubble.
public struct ChatReply: Hashable, Sendable {
    /// The id of the quoted message, if you want to jump to it.
    public var messageID: String?
    /// The quoted message's author, shown in bold.
    public var senderName: String
    /// The quoted text, cut to two lines.
    public var text: String

    public init(messageID: String? = nil, senderName: String, text: String) {
        self.messageID = messageID
        self.senderName = senderName
        self.text = text
    }
}

/// One emoji reaction and how many people chose it.
public struct ChatReaction: Hashable, Sendable, Identifiable {
    public var emoji: String
    public var count: Int
    /// Whether the current user is one of them; the chip is highlighted.
    public var includesMe: Bool

    public var id: String { emoji }

    public init(emoji: String, count: Int = 1, includesMe: Bool = false) {
        self.emoji = emoji
        self.count = count
        self.includesMe = includesMe
    }

    /// The reactions after the current user taps `emoji`: adds the user's reaction, or takes it back
    /// when they had already chosen it. A reaction nobody has any more is removed; a new one goes last.
    ///
    /// ```swift
    /// message.reactions = ChatReaction.toggling("👍", in: message.reactions)
    /// ```
    public static func toggling(_ emoji: String, in reactions: [ChatReaction]) -> [ChatReaction] {
        var result = reactions
        guard let index = result.firstIndex(where: { $0.emoji == emoji }) else {
            result.append(ChatReaction(emoji: emoji, count: 1, includesMe: true))
            return result
        }
        var reaction = result[index]
        if reaction.includesMe {
            reaction.count -= 1
            reaction.includesMe = false
        } else {
            reaction.count += 1
            reaction.includesMe = true
        }
        if reaction.count <= 0 {
            result.remove(at: index)
        } else {
            result[index] = reaction
        }
        return result
    }
}

/// Where an outgoing message is on its way to the other people.
public enum DeliveryStatus: Hashable, Sendable {
    /// Still on its way to your server.
    case sending
    /// Your server has it.
    case sent
    /// It reached the other people's devices.
    case delivered
    /// Someone read it, at `at` when you know the time.
    case read(at: Date? = nil)
    /// It could not be sent. Always shown, not only under the latest message.
    case failed

    /// Whether the message was read.
    public var isRead: Bool {
        if case .read = self { return true }
        return false
    }
}
