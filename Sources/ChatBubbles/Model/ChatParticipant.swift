import SwiftUI

/// Someone in a conversation: the name above their first message in a group, and an avatar with
/// their initials next to the last one.
public struct ChatParticipant: Identifiable, Hashable, Sendable {
    /// Matches ``ChatMessage/senderID``.
    public var id: String
    public var name: String
    /// The avatar color and the color of the name; a neutral gray when `nil`.
    public var color: Color?

    public init(id: String, name: String, color: Color? = nil) {
        self.id = id
        self.name = name
        self.color = color
    }

    /// Up to two letters: the first letters of the first and the last word ("Maya Chen" → "MC").
    public var initials: String {
        Self.initials(for: name)
    }

    /// Up to two uppercased letters from a name, or "?" for an empty name.
    public static func initials(for name: String) -> String {
        let words = name.split(whereSeparator: { $0.isWhitespace || $0 == "-" })
        guard let first = words.first?.first else { return "?" }
        guard words.count > 1, let last = words.last?.first else {
            return String(first).uppercased()
        }
        return (String(first) + String(last)).uppercased()
    }
}
