import Foundation

/// Scenes used by CI to capture the README screenshots on iPhone and the Mac.
///
/// Launch with `-screenshot <scene>`; normal launches are unaffected. An `iphone-` or `mac-` prefix
/// is accepted too, so `-screenshot mac-conversation` is the same as `-screenshot conversation`.
/// Every scene uses a fixed clock (Monday, October 5, 2026, 9:41 AM UTC) and US English.
enum ScreenshotScene: String {
    /// Launch Crew: a day separator, grouped bubbles with names and avatars, reactions and a read
    /// receipt. On the Mac with the sidebar of chats.
    case conversation
    /// Leo is typing, below a reply that quotes his message.
    case typing
    /// The conversation in dark mode.
    case dark

    static var current: ScreenshotScene? {
        guard var name = argument(after: "-screenshot") else { return nil }
        for prefix in ["iphone-", "mac-"] where name.hasPrefix(prefix) {
            name.removeFirst(prefix.count)
        }
        return ScreenshotScene(rawValue: name)
    }

    /// Where `-render-screenshot` asks the PNG to be written (Mac only).
    static var renderPath: String? {
        argument(after: "-render-screenshot")
    }

    private static func argument(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }
}
