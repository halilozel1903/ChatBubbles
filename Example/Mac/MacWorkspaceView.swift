import ChatBubbles
import SwiftUI

/// Huddle on the Mac: the chats on the left, the open conversation on the right.
///
/// Built from plain stacks instead of `NavigationSplitView` and `List`, so it looks the same in a
/// regular window and in the borderless screenshot window.
struct MacWorkspaceView: View {
    let store: ChatStore

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 280)
            Divider()
            conversation
        }
        .background(Color.chatBackground)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Huddle")
                    .font(.title3.weight(.bold))
                Spacer()
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                Text("Search")
                Spacer()
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.bottom, 10)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(store.chats) { chat in
                        ChatRow(store: store, chat: chat, isSelected: chat.id == store.selectedChatID)
                            .onTapGesture {
                                store.selectedChatID = chat.id
                            }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .background(Color.sidebarBackground)
    }

    // MARK: - Conversation

    private var conversation: some View {
        let chat = store.selectedChat
        return VStack(spacing: 0) {
            HStack {
                ChatHeader(store: store, chat: chat)
                Spacer()
                HStack(spacing: 18) {
                    Image(systemName: "video")
                    Image(systemName: "info.circle")
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .frame(height: 56)
            Divider()
            ConversationPane(store: store, chat: chat)
                .id(chat.id)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A chat in the sidebar: icon, name, time, the newest message and the unread count.
private struct ChatRow: View {
    let store: ChatStore
    let chat: DemoChat
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            ChatIcon(chat: chat, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(chat.title)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(store.time(of: chat))
                        .font(.system(size: 11))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary)
                }
                HStack(alignment: .top) {
                    Text(store.preview(of: chat))
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.85) : Color.secondary)
                        .lineLimit(2)
                    Spacer(minLength: 4)
                    if chat.unreadCount > 0 && !isSelected {
                        Text(chat.unreadCount, format: .number)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentBlue, in: Capsule())
                    }
                }
            }
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentBlue)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

extension Color {
    static let accentBlue = Color(red: 0.0, green: 0.48, blue: 1.0)

    static let sidebarBackground = Color.adaptive(
        light: Color(red: 0.96, green: 0.96, blue: 0.97),
        dark: Color(red: 0.12, green: 0.12, blue: 0.13)
    )
}
