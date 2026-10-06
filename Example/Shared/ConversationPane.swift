import ChatBubbles
import SwiftUI

/// One conversation: the messages and the input bar. Shared by the iPhone and Mac apps.
struct ConversationPane: View {
    let store: ChatStore
    let chat: DemoChat

    @State private var draft = ""

    var body: some View {
        let chatID = chat.id
        ChatView(
            messages: store.messages(in: chatID),
            currentUserID: DemoContent.me.id,
            participants: DemoContent.people,
            typingSenderIDs: store.typing(in: chatID),
            dateFormatter: store.dateFormatter,
            showsSenderNames: chat.isGroup,
            showsAvatars: chat.isGroup,
            hasOlderMessages: store.hasOlderMessages(in: chatID),
            loadOlder: { [store] in
                await store.loadOlder(in: chatID)
            },
            onToggleReaction: { message, emoji in
                store.toggleReaction(emoji, on: message.id, in: chatID)
            }
        )
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChatInputBar(
                text: $draft,
                placeholder: "Message \(chat.title)",
                onAttach: { store.sendPhoto(in: chatID) },
                onSend: { text in store.send(text, in: chatID) }
            )
        }
        .background(Color.chatBackground)
    }
}

/// The round icon of a chat: the person's avatar, or a symbol for a group.
struct ChatIcon: View {
    let chat: DemoChat
    var size: CGFloat = 40

    var body: some View {
        if !chat.isGroup, let person = chat.memberIDs.first.flatMap({ DemoContent.participant(withID: $0) }) {
            ChatAvatar(participant: person, size: size)
        } else {
            Circle()
                .fill(chat.color.gradient)
                .frame(width: size, height: size)
                .overlay {
                    Image(systemName: chat.symbol)
                        .font(.system(size: size * 0.42, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)
        }
    }
}

/// The chat's name with its members as overlapping avatars.
struct ChatHeader: View {
    let store: ChatStore
    let chat: DemoChat

    var body: some View {
        HStack(spacing: 10) {
            if chat.isGroup {
                HStack(spacing: -8) {
                    ForEach(store.participants(in: chat)) { person in
                        ChatAvatar(participant: person, size: 26)
                            .overlay(Circle().strokeBorder(Color.chatBackground, lineWidth: 2))
                    }
                }
            } else {
                ChatIcon(chat: chat, size: 28)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(chat.title)
                    .font(.headline)
                if let subtitle = chat.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension Color {
    /// The background behind the bubbles.
    static let chatBackground = Color.adaptive(
        light: .white,
        dark: Color(red: 0.06, green: 0.06, blue: 0.07)
    )
}
