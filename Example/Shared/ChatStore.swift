import ChatBubbles
import Observation
import SwiftUI

/// The demo's messages. Sending a message marks it delivered and read, then someone types and answers.
@MainActor
@Observable
final class ChatStore {
    let chats: [DemoChat]
    var selectedChatID: String
    let dateFormatter: ChatDateFormatter

    private(set) var messagesByChat: [String: [SimpleMessage]]
    private(set) var typingByChat: [String: [String]] = [:]
    private var olderPages: [String: [[SimpleMessage]]]
    private let simulatesReplies: Bool
    private var replyIndex = 0

    init(
        now: Date,
        calendar: Calendar,
        locale: Locale,
        simulatesReplies: Bool,
        includesOlderMessages: Bool
    ) {
        chats = DemoContent.chats
        selectedChatID = DemoContent.launchCrewID
        dateFormatter = ChatDateFormatter(calendar: calendar, locale: locale, now: now)
        var messages = DemoContent.otherChats(now: now, calendar: calendar)
        messages[DemoContent.launchCrewID] = DemoContent.launchCrew(now: now, calendar: calendar)
        messagesByChat = messages
        olderPages = includesOlderMessages
            ? [DemoContent.launchCrewID: DemoContent.launchCrewOlderPages(now: now, calendar: calendar)]
            : [:]
        self.simulatesReplies = simulatesReplies
    }

    /// The interactive demo: the real clock and region, replies and older messages.
    static func live() -> ChatStore {
        ChatStore(now: .now, calendar: .current, locale: .current, simulatesReplies: true, includesOlderMessages: true)
    }

    /// A fixed state for a README screenshot: a fixed clock, US English, nothing moves.
    static func screenshot(_ scene: ScreenshotScene) -> ChatStore {
        let store = ChatStore(
            now: DemoContent.screenshotNow,
            calendar: DemoContent.screenshotCalendar,
            locale: DemoContent.screenshotLocale,
            simulatesReplies: false,
            includesOlderMessages: false
        )
        if scene == .typing {
            store.messagesByChat[DemoContent.launchCrewID, default: []].append(
                DemoContent.launchCrewReply(now: DemoContent.screenshotNow, calendar: DemoContent.screenshotCalendar)
            )
            store.typingByChat[DemoContent.launchCrewID] = ["leo"]
        }
        return store
    }

    // MARK: - Reading

    var selectedChat: DemoChat {
        chat(withID: selectedChatID)
    }

    func chat(withID id: String) -> DemoChat {
        chats.first { $0.id == id } ?? chats[0]
    }

    func messages(in chatID: String) -> [SimpleMessage] {
        messagesByChat[chatID] ?? []
    }

    func typing(in chatID: String) -> [String] {
        typingByChat[chatID] ?? []
    }

    func hasOlderMessages(in chatID: String) -> Bool {
        !(olderPages[chatID]?.isEmpty ?? true)
    }

    func participants(in chat: DemoChat) -> [ChatParticipant] {
        chat.memberIDs.compactMap { DemoContent.participant(withID: $0) }
    }

    /// The newest message's text for the sidebar, with "You: " before your own.
    func preview(of chat: DemoChat) -> String {
        guard let last = messages(in: chat.id).last else { return "" }
        let text = last.text.isEmpty ? "Photo" : String(MessageText.attributedString(from: last.text).characters)
        return last.senderID == DemoContent.me.id ? "You: \(text)" : text
    }

    /// "9:38 AM" today, "Yesterday", "Saturday" or a date before that.
    func time(of chat: DemoChat) -> String {
        guard let last = messages(in: chat.id).last else { return "" }
        return dateFormatter.daysAgo(last.sentAt) == 0
            ? dateFormatter.time(for: last.sentAt)
            : dateFormatter.dayTitle(for: last.sentAt)
    }

    // MARK: - Changing

    func send(_ text: String, in chatID: String) {
        append(SimpleMessage(senderID: DemoContent.me.id, sentAt: .now, text: text, status: .sending), to: chatID)
    }

    func sendPhoto(in chatID: String) {
        append(
            SimpleMessage(
                senderID: DemoContent.me.id,
                sentAt: .now,
                attachment: .image(name: "LaunchBoard", aspectRatio: 4.0 / 3.0, description: "The Atlas 2.0 launch graphic"),
                status: .sending
            ),
            to: chatID
        )
    }

    func toggleReaction(_ emoji: String, on messageID: String, in chatID: String) {
        guard var messages = messagesByChat[chatID],
              let index = messages.firstIndex(where: { $0.id == messageID })
        else { return }
        messages[index].reactions = ChatReaction.toggling(emoji, in: messages[index].reactions)
        messagesByChat[chatID] = messages
    }

    func loadOlder(in chatID: String) async {
        try? await Task.sleep(for: .milliseconds(700))
        guard var pages = olderPages[chatID], let page = pages.popLast() else { return }
        olderPages[chatID] = pages
        messagesByChat[chatID, default: []].insert(contentsOf: page, at: 0)
    }

    private func append(_ message: SimpleMessage, to chatID: String) {
        messagesByChat[chatID, default: []].append(message)
        guard simulatesReplies else { return }

        let conversation = chat(withID: chatID)
        let responderID = conversation.memberIDs.first ?? DemoContent.leo.id
        let reply = DemoContent.replies[replyIndex % DemoContent.replies.count]
        let messageID = message.id
        replyIndex += 1

        Task {
            try? await Task.sleep(for: .milliseconds(500))
            self.setStatus(.delivered, of: messageID, in: chatID)
            try? await Task.sleep(for: .milliseconds(900))
            self.setStatus(.read(at: .now), of: messageID, in: chatID)
            self.typingByChat[chatID] = [responderID]
            try? await Task.sleep(for: .seconds(2))
            self.typingByChat[chatID] = []
            self.messagesByChat[chatID, default: []].append(
                SimpleMessage(senderID: responderID, sentAt: .now, text: reply)
            )
        }
    }

    private func setStatus(_ status: DeliveryStatus, of messageID: String, in chatID: String) {
        guard var messages = messagesByChat[chatID],
              let index = messages.firstIndex(where: { $0.id == messageID })
        else { return }
        messages[index].status = status
        messagesByChat[chatID] = messages
    }
}
