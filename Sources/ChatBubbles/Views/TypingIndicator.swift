import SwiftUI

/// Three dots in an incoming bubble that rise and fall in a wave while someone is typing.
///
/// With Reduce Motion on, the dots stand still in three shades instead.
///
/// ```swift
/// if isLeoTyping {
///     TypingIndicator()
/// }
/// ```
public struct TypingIndicator: View {
    private let dotSize: CGFloat

    @Environment(\.chatTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.typingIndicatorFrozenTime) private var frozenTime

    /// - Parameter dotSize: The diameter of each dot in points.
    public init(dotSize: CGFloat = 8) {
        self.dotSize = dotSize
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || frozenTime != nil)) { context in
            let time = frozenTime ?? context.date.timeIntervalSinceReferenceDate
            HStack(spacing: dotSize * 0.55) {
                ForEach(0..<3, id: \.self) { index in
                    let lift = reduceMotion ? 0 : TypingAnimation.lift(at: time, dot: index)
                    Circle()
                        .fill(theme.incomingForeground)
                        .frame(width: dotSize, height: dotSize)
                        .opacity(reduceMotion ? TypingAnimation.staticOpacity(dot: index) : 0.35 + 0.5 * lift)
                        .offset(y: -dotSize * 0.45 * CGFloat(lift))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12 + dotSize * 0.25)
            .padding(.bottom, 12)
        }
        .padding(.leading, theme.tailWidth)
        .background(
            BubbleShape(
                position: .single,
                isOutgoing: false,
                radius: theme.cornerRadius,
                groupedRadius: theme.groupedCornerRadius,
                showsTail: theme.showsTails,
                tailWidth: theme.tailWidth
            )
            .fill(theme.incomingBackground)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Typing"))
    }
}

private struct TypingIndicatorFrozenTimeKey: EnvironmentKey {
    static let defaultValue: TimeInterval? = nil
}

extension EnvironmentValues {
    /// When set, typing indicators below stand still at this point of their wave. See
    /// `typingIndicatorFrozen(at:)`.
    public var typingIndicatorFrozenTime: TimeInterval? {
        get { self[TypingIndicatorFrozenTimeKey.self] }
        set { self[TypingIndicatorFrozenTimeKey.self] = newValue }
    }
}

extension View {
    /// Stops the typing indicators in this view at one frame of their wave, `time` seconds into it,
    /// so previews, snapshot tests and screenshots always look the same.
    ///
    /// ```swift
    /// ChatView(messages: messages, currentUserID: "me", typingSenderIDs: ["leo"])
    ///     .typingIndicatorFrozen(at: 0.3)     // the first dot at the top of its wave
    /// ```
    public func typingIndicatorFrozen(at time: TimeInterval?) -> some View {
        environment(\.typingIndicatorFrozenTime, time)
    }
}
