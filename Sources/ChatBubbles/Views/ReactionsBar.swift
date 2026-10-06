import SwiftUI

/// Emoji reactions under a bubble: one chip per emoji with its count. Your own reactions are
/// highlighted in the accent color.
///
/// ```swift
/// ReactionsBar(reactions: message.reactions) { reaction in
///     message.reactions = ChatReaction.toggling(reaction.emoji, in: message.reactions)
/// }
/// ```
public struct ReactionsBar: View {
    private let reactions: [ChatReaction]
    private let onTap: ((ChatReaction) -> Void)?

    @Environment(\.chatTheme) private var theme

    /// - Parameters:
    ///   - reactions: The reactions, shown in this order. Reactions with a count below one are skipped.
    ///   - onTap: Called when a chip is tapped or clicked; the chips are plain labels when `nil`.
    public init(reactions: [ChatReaction], onTap: ((ChatReaction) -> Void)? = nil) {
        self.reactions = reactions
        self.onTap = onTap
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(reactions.filter { $0.count > 0 }) { reaction in
                if let onTap {
                    Button {
                        onTap(reaction)
                    } label: {
                        chip(for: reaction)
                    }
                    .buttonStyle(.plain)
                } else {
                    chip(for: reaction)
                }
            }
        }
    }

    private func chip(for reaction: ChatReaction) -> some View {
        HStack(spacing: 3) {
            Text(reaction.emoji)
                .font(.system(size: 13))
            if reaction.count > 1 {
                Text(reaction.count, format: .number)
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(reaction.includesMe ? theme.accent : theme.metadataColor)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background {
            Capsule()
                .fill(theme.reactionBackground)
                .overlay {
                    if reaction.includesMe {
                        Capsule().fill(theme.accent.opacity(0.16))
                    }
                }
                .shadow(color: .black.opacity(0.12), radius: 1.5, y: 0.5)
        }
        .overlay {
            Capsule()
                .strokeBorder(reaction.includesMe ? theme.accent.opacity(0.55) : Color.primary.opacity(0.08), lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Self.accessibilityText(for: reaction)))
        .accessibilityAddTraits(reaction.includesMe ? .isSelected : [])
    }

    private static func accessibilityText(for reaction: ChatReaction) -> String {
        let people = reaction.count == 1 ? "1 person" : "\(reaction.count) people"
        return "\(reaction.emoji), \(people)"
    }
}

/// A round avatar with a participant's initials.
public struct ChatAvatar: View {
    private let participant: ChatParticipant
    private let size: CGFloat

    public init(participant: ChatParticipant, size: CGFloat = 28) {
        self.participant = participant
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill((participant.color ?? .gray).gradient)
            .frame(width: size, height: size)
            .overlay {
                Text(participant.initials)
                    .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(participant.name))
    }
}
