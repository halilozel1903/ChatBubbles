import ChatBubbles
import SwiftUI

@main
struct ChatBubblesDemoApp: App {
    @State private var store = ChatStore.live()

    var body: some Scene {
        WindowGroup {
            if let scene = ScreenshotScene.current {
                // Screenshot scenes use a fixed clock and fixed messages.
                ScreenshotView(scene: scene)
            } else {
                ChatListView(store: store)
            }
        }
    }
}

/// Huddle's chats; tapping one opens the conversation.
struct ChatListView: View {
    let store: ChatStore

    var body: some View {
        NavigationStack {
            List(store.chats) { chat in
                NavigationLink(value: chat.id) {
                    HStack(spacing: 12) {
                        ChatIcon(chat: chat, size: 46)
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(chat.title)
                                    .font(.headline)
                                Spacer()
                                Text(store.time(of: chat))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(store.preview(of: chat))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Huddle")
            .navigationDestination(for: String.self) { chatID in
                PhoneConversationScreen(store: store, chat: store.chat(withID: chatID))
            }
        }
    }
}

/// A conversation with the chat's members in the navigation bar.
struct PhoneConversationScreen: View {
    let store: ChatStore
    let chat: DemoChat

    var body: some View {
        ConversationPane(store: store, chat: chat)
            .navigationTitle(chat.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ChatHeader(store: store, chat: chat)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Call", systemImage: "video") {}
                }
            }
    }
}

/// Renders one scene for CI. Writes `tmp/screenshot-ready` once it is on screen, which
/// scripts/screenshots.sh waits for.
struct ScreenshotView: View {
    let scene: ScreenshotScene

    @State private var store: ChatStore

    init(scene: ScreenshotScene) {
        self.scene = scene
        _store = State(initialValue: ChatStore.screenshot(scene))
    }

    var body: some View {
        NavigationStack {
            PhoneConversationScreen(store: store, chat: store.chat(withID: DemoContent.launchCrewID))
        }
        .preferredColorScheme(scene == .dark ? .dark : .light)
        // One fixed frame of the typing animation, so every capture is the same.
        .typingIndicatorFrozen(at: 0.3)
        .task {
            // Tells scripts/screenshots.sh that the scene is on screen.
            let marker = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("screenshot-ready")
            try? await Task.sleep(for: .seconds(1))
            try? scene.rawValue.write(to: marker, atomically: true, encoding: .utf8)
        }
    }
}
