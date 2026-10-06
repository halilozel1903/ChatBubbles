import SwiftUI

/// A scrolling conversation: day separators, grouped bubbles with tails, names and avatars in group
/// chats, timestamps, reactions, the delivery status of your latest message and a typing indicator.
///
/// It opens at the newest message, follows new messages while you are at the bottom (and always
/// for your own), keeps your place when older messages are loaded at the top, and shows a button
/// that jumps back down when you have scrolled away.
///
/// ```swift
/// ChatView(
///     messages: model.messages,                       // oldest first
///     currentUserID: model.me.id,
///     participants: model.members,                    // names and avatars
///     typingSenderIDs: model.typing,
///     hasOlderMessages: model.hasMore,
///     loadOlder: { await model.loadOlder() },
///     onToggleReaction: { message, emoji in model.toggle(emoji, on: message) }
/// )
/// .safeAreaInset(edge: .bottom, spacing: 0) {
///     ChatInputBar(text: $draft) { model.send($0) }
/// }
/// ```
public struct ChatView<Message: ChatMessage>: View {
    private let messages: [Message]
    private let grouping: MessageGrouping
    private let participants: [String: ChatParticipant]
    private let typingSenderIDs: [String]
    private let dateFormatter: ChatDateFormatter
    private let showsSenderNames: Bool
    private let showsAvatars: Bool
    private let quickReactions: [String]
    private let hasOlderMessages: Bool
    private let loadOlder: (@Sendable () async -> Void)?
    private let onToggleReaction: ((Message, String) -> Void)?

    @Environment(\.chatTheme) private var theme
    @State private var isNearBottom = true
    @State private var isLoadingOlder = false
    @State private var olderAnchor: Message.ID?

    /// - Parameters:
    ///   - messages: The conversation, oldest first.
    ///   - currentUserID: Messages with this ``ChatMessage/senderID`` are outgoing.
    ///   - participants: Names, colors and initials of the other people, by id.
    ///   - typingSenderIDs: Who is typing right now; the indicator shows while this is not empty.
    ///   - dateFormatter: Day separators, times and receipts; inject `now`, the calendar and the
    ///     locale for previews and tests.
    ///   - maximumGroupGap: The longest pause, in seconds, between messages of one group.
    ///   - showsSenderNames: The name above the first incoming bubble of a group, when the sender is
    ///     one of `participants`. Turn it off for one-to-one chats.
    ///   - showsAvatars: An avatar next to the last incoming bubble of a group.
    ///   - quickReactions: The emoji offered in a bubble's context menu when `onToggleReaction` is set.
    ///   - hasOlderMessages: Shows a spinner above the oldest message that calls `loadOlder` when it
    ///     scrolls into view.
    ///   - loadOlder: Loads older messages and adds them to the start of `messages`.
    ///   - onToggleReaction: Called when the user taps a reaction chip or picks an emoji from the
    ///     context menu. Update the message, for example with ``ChatReaction/toggling(_:in:)``.
    public init(
        messages: [Message],
        currentUserID: String,
        participants: [ChatParticipant] = [],
        typingSenderIDs: [String] = [],
        dateFormatter: ChatDateFormatter = ChatDateFormatter(),
        maximumGroupGap: TimeInterval = 5 * 60,
        showsSenderNames: Bool = true,
        showsAvatars: Bool = true,
        quickReactions: [String] = ["👍", "❤️", "😂", "🎉", "😮", "🙏"],
        hasOlderMessages: Bool = false,
        loadOlder: (@Sendable () async -> Void)? = nil,
        onToggleReaction: ((Message, String) -> Void)? = nil
    ) {
        self.messages = messages
        self.grouping = MessageGrouping(
            currentUserID: currentUserID,
            maximumGap: maximumGroupGap,
            calendar: dateFormatter.calendar
        )
        self.participants = Dictionary(participants.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.typingSenderIDs = typingSenderIDs
        self.dateFormatter = dateFormatter
        self.showsSenderNames = showsSenderNames
        self.showsAvatars = showsAvatars
        self.quickReactions = quickReactions
        self.hasOlderMessages = hasOlderMessages
        self.loadOlder = loadOlder
        self.onToggleReaction = onToggleReaction
    }

    public var body: some View {
        let items = grouping.items(for: messages)
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if hasOlderMessages, loadOlder != nil {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .task(id: messages.first?.id) {
                                await loadOlderMessages()
                            }
                    }

                    ForEach(items) { item in
                        row(for: item)
                            .id(item.id)
                    }

                    if !typingSenderIDs.isEmpty {
                        typingRow
                            .id(typingRowID)
                            .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .bottomLeading)))
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(bottomRowID)
                        .onAppear { isNearBottom = true }
                        .onDisappear { isNearBottom = false }
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .animation(.smooth(duration: 0.25), value: typingSenderIDs.isEmpty)
            }
            .defaultScrollAnchor(.bottom)
            .onChange(of: messages.map(\.id)) { oldIDs, newIDs in
                handle(TranscriptChange.between(oldIDs, newIDs), proxy: proxy)
            }
            .onChange(of: typingSenderIDs.isEmpty) { _, isEmpty in
                if !isEmpty && isNearBottom {
                    withAnimation(.smooth) {
                        proxy.scrollTo(bottomRowID, anchor: .bottom)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                ZStack {
                    if !isNearBottom {
                        Button {
                            withAnimation(.smooth) {
                                proxy.scrollTo(bottomRowID, anchor: .bottom)
                            }
                        } label: {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 36, height: 36)
                                .background(.regularMaterial, in: Circle())
                                .overlay(Circle().strokeBorder(Color.primary.opacity(0.08)))
                                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                        }
                        .buttonStyle(.plain)
                        .padding(16)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        .accessibilityLabel(Text("Scroll to the newest message"))
                    }
                }
                .animation(.smooth(duration: 0.2), value: isNearBottom)
            }
        }
    }

    // MARK: - Rows

    @ViewBuilder
    private func row(for item: ChatTranscriptItem<Message>) -> some View {
        switch item {
        case .daySeparator(let day):
            Text(dateFormatter.dayTitle(for: day))
                .font(theme.metadataFont.weight(.semibold))
                .foregroundStyle(theme.metadataColor)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)
        case .message(let entry):
            MessageRow(
                entry: entry,
                participant: participants[entry.message.senderID],
                showsSenderName: showsSenderNames,
                showsAvatar: showsAvatars && !participants.isEmpty,
                dateFormatter: dateFormatter,
                quickReactions: onToggleReaction == nil ? [] : quickReactions,
                onToggleReaction: onToggleReaction.map { toggle in
                    { (emoji: String) in toggle(entry.message, emoji) }
                }
            )
        }
    }

    private var typingRow: some View {
        HStack(alignment: .bottom, spacing: 6) {
            if showsAvatars, let participant = typingSenderIDs.lazy.compactMap({ participants[$0] }).first {
                ChatAvatar(participant: participant, size: MessageRowMetrics.avatarSize)
            }
            TypingIndicator()
            Spacer(minLength: 0)
        }
        .padding(.top, theme.groupSpacing)
    }

    // MARK: - Scrolling

    private func handle(_ change: TranscriptChange, proxy: ScrollViewProxy) {
        switch change {
        case .prepended:
            if let anchor = olderAnchor {
                proxy.scrollTo(ChatTranscriptItem<Message>.ItemID.message(anchor), anchor: .top)
            }
            olderAnchor = nil
        case .appended, .replaced:
            let lastIsOutgoing = messages.last.map { grouping.isOutgoing($0) } ?? false
            if change.scrollsToBottom(lastMessageIsOutgoing: lastIsOutgoing, isNearBottom: isNearBottom) {
                withAnimation(.smooth) {
                    proxy.scrollTo(bottomRowID, anchor: .bottom)
                }
            }
        case .none:
            break
        }
    }

    private func loadOlderMessages() async {
        guard let loadOlder, !isLoadingOlder else { return }
        isLoadingOlder = true
        olderAnchor = messages.first?.id
        await loadOlder()
        isLoadingOlder = false
    }
}

private let bottomRowID = "ChatBubbles.bottom"
private let typingRowID = "ChatBubbles.typing"

enum MessageRowMetrics {
    static let avatarSize: CGFloat = 28
    static let avatarSpacing: CGFloat = 6
    /// Room kept on the other side, so a bubble never spans the whole width.
    static let oppositeInset: CGFloat = 56
}

/// One message with its name, avatar, reactions and footer.
private struct MessageRow<Message: ChatMessage>: View {
    let entry: ChatTranscriptMessage<Message>
    let participant: ChatParticipant?
    let showsSenderName: Bool
    let showsAvatar: Bool
    let dateFormatter: ChatDateFormatter
    let quickReactions: [String]
    let onToggleReaction: ((String) -> Void)?

    @Environment(\.chatTheme) private var theme

    private var isOutgoing: Bool { entry.isOutgoing }

    /// The space before the bubble's body: the avatar column and the tail strip.
    private var innerInset: CGFloat {
        let avatar = !isOutgoing && showsAvatar ? MessageRowMetrics.avatarSize + MessageRowMetrics.avatarSpacing : 0
        return avatar + theme.tailWidth
    }

    var body: some View {
        HStack(spacing: 0) {
            if isOutgoing {
                Spacer(minLength: MessageRowMetrics.oppositeInset)
            }
            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 3) {
                if !isOutgoing, showsSenderName, entry.position.isGroupStart, let participant {
                    Text(participant.name)
                        .font(theme.metadataFont.weight(.semibold))
                        .foregroundStyle(participant.color ?? theme.metadataColor)
                        .padding(.leading, innerInset + 12)
                }

                HStack(alignment: .bottom, spacing: MessageRowMetrics.avatarSpacing) {
                    if !isOutgoing && showsAvatar {
                        if entry.position.isGroupEnd, let participant {
                            ChatAvatar(participant: participant, size: MessageRowMetrics.avatarSize)
                        } else {
                            Color.clear
                                .frame(width: MessageRowMetrics.avatarSize, height: 1)
                        }
                    }
                    bubble
                }

                if !entry.message.reactions.isEmpty {
                    ReactionsBar(reactions: entry.message.reactions, onTap: onToggleReaction.map { toggle in
                        { (reaction: ChatReaction) in toggle(reaction.emoji) }
                    })
                    .padding(.top, -9)
                    .padding(isOutgoing ? .trailing : .leading, innerInset + 8)
                }

                if let footer {
                    Text(footer)
                        .font(theme.metadataFont)
                        .foregroundStyle(entry.message.status == .failed && entry.showsStatus ? Color.red : theme.metadataColor)
                        .padding(isOutgoing ? .trailing : .leading, innerInset + 4)
                }
            }
            .frame(maxWidth: theme.maximumBubbleWidth, alignment: isOutgoing ? .trailing : .leading)
            if !isOutgoing {
                Spacer(minLength: MessageRowMetrics.oppositeInset)
            }
        }
        .padding(.top, entry.position.isGroupStart ? theme.groupSpacing : theme.bubbleSpacing)
    }

    @ViewBuilder
    private var bubble: some View {
        let content = MessageBubble(message: entry.message, isOutgoing: isOutgoing, position: entry.position)
        if let onToggleReaction, !quickReactions.isEmpty {
            content.contextMenu {
                ForEach(quickReactions, id: \.self) { emoji in
                    Button(emoji) {
                        onToggleReaction(emoji)
                    }
                }
            }
        } else {
            content
        }
    }

    /// The receipt under the latest outgoing message, otherwise the time under the last bubble of a
    /// group.
    private var footer: String? {
        if entry.showsStatus {
            return dateFormatter.receipt(for: entry.message.status)
        }
        if entry.showsTimestamp {
            return dateFormatter.time(for: entry.message.sentAt)
        }
        return nil
    }
}
