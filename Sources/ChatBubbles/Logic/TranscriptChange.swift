import Foundation

/// How the list of messages changed between two updates, used to decide where to scroll.
public enum TranscriptChange: Hashable, Sendable {
    /// The same messages in the same order (their contents may have changed, like reactions).
    case none
    /// New messages at the end.
    case appended
    /// Older messages at the start, after "load older".
    case prepended
    /// Anything else: the first load, another conversation, removed or reordered messages.
    case replaced

    /// Compares the message ids before and after an update.
    public static func between<ID: Equatable>(_ old: [ID], _ new: [ID]) -> TranscriptChange {
        if old == new { return .none }
        guard !old.isEmpty, new.count > old.count else { return .replaced }
        if new.starts(with: old) { return .appended }
        if Array(new.suffix(old.count)) == old { return .prepended }
        return .replaced
    }

    /// Whether the chat should scroll to the newest message after this change.
    ///
    /// Your own new message always scrolls into view. Someone else's only does when you were already
    /// at the bottom, so reading older messages is never interrupted. Loading older messages keeps
    /// the position instead.
    public func scrollsToBottom(lastMessageIsOutgoing: Bool, isNearBottom: Bool) -> Bool {
        switch self {
        case .appended: lastMessageIsOutgoing || isNearBottom
        case .replaced: true
        case .none, .prepended: false
        }
    }
}
