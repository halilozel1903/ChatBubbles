import Foundation

/// Turns a list of messages into what a chat shows: day separators, and every message with its
/// position in a group, its side, and whether it shows a timestamp and a delivery status.
///
/// Consecutive messages from the same sender belong to one group while each one follows the previous
/// within `maximumGap` on the same day.
///
/// ```swift
/// let grouping = MessageGrouping(currentUserID: "me", maximumGap: 5 * 60)
/// for item in grouping.items(for: messages) {
///     switch item {
///     case .daySeparator(let day): print(formatter.dayTitle(for: day))
///     case .message(let entry): print(entry.message.text, entry.position)
///     }
/// }
/// ```
public struct MessageGrouping: Sendable {
    /// Messages from this sender are outgoing: on the trailing side, in the accent color.
    public var currentUserID: String
    /// The longest pause between two messages of one group, in seconds. Five minutes by default.
    public var maximumGap: TimeInterval
    /// Decides where days start. Use the same calendar as your ``ChatDateFormatter``.
    public var calendar: Calendar
    /// Whether a day separator comes before the first message of every day.
    public var showsDaySeparators: Bool

    public init(
        currentUserID: String,
        maximumGap: TimeInterval = 5 * 60,
        calendar: Calendar = .current,
        showsDaySeparators: Bool = true
    ) {
        self.currentUserID = currentUserID
        self.maximumGap = maximumGap
        self.calendar = calendar
        self.showsDaySeparators = showsDaySeparators
    }

    /// Whether the current user sent `message`.
    public func isOutgoing<Message: ChatMessage>(_ message: Message) -> Bool {
        message.senderID == currentUserID
    }

    /// Whether `message` joins the group of `previous`: same sender, same day, sent at most
    /// `maximumGap` later (and not earlier).
    public func continues<Message: ChatMessage>(_ message: Message, after previous: Message) -> Bool {
        guard message.senderID == previous.senderID else { return false }
        let gap = message.sentAt.timeIntervalSince(previous.sentAt)
        guard gap >= 0, gap <= maximumGap else { return false }
        return calendar.isDate(message.sentAt, inSameDayAs: previous.sentAt)
    }

    /// The position of every message, in the same order. Messages should be oldest first.
    public func positions<Message: ChatMessage>(for messages: [Message]) -> [BubblePosition] {
        messages.indices.map { index in
            let continuesPrevious = index > messages.startIndex
                && continues(messages[index], after: messages[index - 1])
            let continuesNext = index + 1 < messages.endIndex
                && continues(messages[index + 1], after: messages[index])
            return BubblePosition(continuesPrevious: continuesPrevious, continuesNext: continuesNext)
        }
    }

    /// The rows of a chat: a day separator before each new day, then the messages. Pass the
    /// messages oldest first.
    ///
    /// The latest outgoing message shows its ``DeliveryStatus``; failed messages always do. The last
    /// message of every group shows a timestamp.
    public func items<Message: ChatMessage>(for messages: [Message]) -> [ChatTranscriptItem<Message>] {
        let groupPositions = self.positions(for: messages)
        let lastOutgoingIndex = messages.lastIndex { $0.senderID == currentUserID }
        var items: [ChatTranscriptItem<Message>] = []
        items.reserveCapacity(messages.count + 4)
        var shownDays = Set<Date>()
        var currentDay: Date?

        for (index, message) in messages.enumerated() {
            let day = calendar.startOfDay(for: message.sentAt)
            if showsDaySeparators, day != currentDay, !shownDays.contains(day) {
                items.append(.daySeparator(day))
                shownDays.insert(day)
            }
            currentDay = day

            let outgoing = message.senderID == currentUserID
            let showsStatus = outgoing && (index == lastOutgoingIndex || message.status == .failed)
            items.append(.message(ChatTranscriptMessage(
                message: message,
                position: groupPositions[index],
                isOutgoing: outgoing,
                showsTimestamp: groupPositions[index].isGroupEnd,
                showsStatus: showsStatus
            )))
        }
        return items
    }
}

/// One row of a chat: a day separator or a message.
public enum ChatTranscriptItem<Message: ChatMessage>: Identifiable {
    /// The first message of a new day follows. The date is the start of that day.
    case daySeparator(Date)
    /// A message with its place in the conversation.
    case message(ChatTranscriptMessage<Message>)

    /// A stable identity for `ForEach` and `ScrollViewReader`.
    public enum ItemID: Hashable {
        case daySeparator(Date)
        case message(Message.ID)
    }

    public var id: ItemID {
        switch self {
        case .daySeparator(let day): .daySeparator(day)
        case .message(let entry): .message(entry.message.id)
        }
    }

    /// The message of a `.message` row.
    public var message: ChatTranscriptMessage<Message>? {
        if case .message(let entry) = self { return entry }
        return nil
    }

    /// The day of a `.daySeparator` row.
    public var day: Date? {
        if case .daySeparator(let day) = self { return day }
        return nil
    }
}

/// A message with everything a row needs to draw it.
public struct ChatTranscriptMessage<Message: ChatMessage>: Identifiable {
    public let message: Message
    /// Its place in the group of consecutive messages from the same sender.
    public let position: BubblePosition
    /// Sent by the current user.
    public let isOutgoing: Bool
    /// The last message of a group shows its time.
    public let showsTimestamp: Bool
    /// The latest outgoing message, or a failed one, shows its delivery status.
    public let showsStatus: Bool

    public var id: Message.ID { message.id }

    public init(message: Message, position: BubblePosition, isOutgoing: Bool, showsTimestamp: Bool, showsStatus: Bool) {
        self.message = message
        self.position = position
        self.isOutgoing = isOutgoing
        self.showsTimestamp = showsTimestamp
        self.showsStatus = showsStatus
    }
}
