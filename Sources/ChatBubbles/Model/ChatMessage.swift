import Foundation

/// A message that ChatBubbles can group and draw.
///
/// Conform your own message type, or use ``SimpleMessage``. Only `id`, `senderID`, `sentAt` and
/// `text` are required; the other requirements have defaults (no attachment, no reply, no reactions,
/// `.sent`).
///
/// ```swift
/// struct Note: ChatMessage {
///     let id: UUID
///     let senderID: String
///     let sentAt: Date
///     let text: String
/// }
/// ```
public protocol ChatMessage: Identifiable {
    /// Who wrote the message. Compared with the current user's id to decide outgoing or incoming.
    var senderID: String { get }
    /// When the message was sent. Messages are grouped and separated by day with this date.
    var sentAt: Date { get }
    /// The text, with inline Markdown (`**bold**`, `*italic*`, `` `code` ``, `[links](…)`). Bare URLs
    /// become links. May be empty for a message that is only an attachment.
    var text: String { get }
    /// An image shown above the text.
    var attachment: ChatAttachment? { get }
    /// The message this one answers, shown as a quote at the top of the bubble.
    var reply: ChatReply? { get }
    /// Emoji reactions, shown under the bubble in this order.
    var reactions: [ChatReaction] { get }
    /// Delivery state of an outgoing message, shown under the latest outgoing message.
    var status: DeliveryStatus { get }
}

extension ChatMessage {
    public var attachment: ChatAttachment? { nil }
    public var reply: ChatReply? { nil }
    public var reactions: [ChatReaction] { [] }
    public var status: DeliveryStatus { .sent }
}

/// A ready-made ``ChatMessage``.
public struct SimpleMessage: ChatMessage, Hashable, Sendable {
    public var id: String
    public var senderID: String
    public var sentAt: Date
    public var text: String
    public var attachment: ChatAttachment?
    public var reply: ChatReply?
    public var reactions: [ChatReaction]
    public var status: DeliveryStatus

    public init(
        id: String = UUID().uuidString,
        senderID: String,
        sentAt: Date = .now,
        text: String = "",
        attachment: ChatAttachment? = nil,
        reply: ChatReply? = nil,
        reactions: [ChatReaction] = [],
        status: DeliveryStatus = .sent
    ) {
        self.id = id
        self.senderID = senderID
        self.sentAt = sentAt
        self.text = text
        self.attachment = attachment
        self.reply = reply
        self.reactions = reactions
        self.status = status
    }
}
