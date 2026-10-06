import CoreGraphics

/// Where a bubble sits in a group of consecutive messages from the same sender.
///
/// The position decides the corner radii (bubbles that touch get tighter corners on the sender's
/// side), the tail (only the last bubble of a group has one), the sender's name (above the first)
/// and the avatar (next to the last).
public enum BubblePosition: String, Hashable, Sendable, CaseIterable {
    /// A group of one message.
    case single
    /// The first of several messages.
    case first
    /// Neither first nor last.
    case middle
    /// The last of several messages.
    case last

    public init(continuesPrevious: Bool, continuesNext: Bool) {
        switch (continuesPrevious, continuesNext) {
        case (false, false): self = .single
        case (false, true): self = .first
        case (true, true): self = .middle
        case (true, false): self = .last
        }
    }

    /// `single` or `first`: the bubble starts a group.
    public var isGroupStart: Bool { self == .single || self == .first }

    /// `single` or `last`: the bubble ends a group, gets the tail and the timestamp.
    public var isGroupEnd: Bool { self == .single || self == .last }
}

/// Which side of the conversation a bubble is on: `trailing` for your own messages.
public enum BubbleSide: Hashable, Sendable {
    case leading
    case trailing
}

/// The four corner radii of a bubble.
public struct BubbleCorners: Hashable, Sendable {
    public var topLeading: CGFloat
    public var topTrailing: CGFloat
    public var bottomLeading: CGFloat
    public var bottomTrailing: CGFloat

    public init(topLeading: CGFloat, topTrailing: CGFloat, bottomLeading: CGFloat, bottomTrailing: CGFloat) {
        self.topLeading = topLeading
        self.topTrailing = topTrailing
        self.bottomLeading = bottomLeading
        self.bottomTrailing = bottomTrailing
    }

    /// The same radius on every corner.
    public init(all radius: CGFloat) {
        self.init(topLeading: radius, topTrailing: radius, bottomLeading: radius, bottomTrailing: radius)
    }

    /// The corners for a bubble at `position`: `radius` everywhere, except `groupedRadius` on the
    /// sender's side where the bubble touches the one above or below.
    ///
    /// | Position | Sender's side, top | Sender's side, bottom |
    /// | --- | --- | --- |
    /// | `single` | `radius` | `radius` (or the tail) |
    /// | `first` | `radius` | `groupedRadius` |
    /// | `middle` | `groupedRadius` | `groupedRadius` |
    /// | `last` | `groupedRadius` | `radius` (or the tail) |
    public init(position: BubblePosition, isOutgoing: Bool, radius: CGFloat, groupedRadius: CGFloat) {
        let senderTop = position.isGroupStart ? radius : groupedRadius
        let senderBottom = position.isGroupEnd ? radius : groupedRadius
        if isOutgoing {
            self.init(topLeading: radius, topTrailing: senderTop, bottomLeading: radius, bottomTrailing: senderBottom)
        } else {
            self.init(topLeading: senderTop, topTrailing: radius, bottomLeading: senderBottom, bottomTrailing: radius)
        }
    }

    /// Leading and trailing swapped.
    public var mirrored: BubbleCorners {
        BubbleCorners(topLeading: topTrailing, topTrailing: topLeading, bottomLeading: bottomTrailing, bottomTrailing: bottomLeading)
    }

    /// Every radius limited to `limit`, so the corners of a small bubble never overlap.
    public func clamped(to limit: CGFloat) -> BubbleCorners {
        let limit = max(0, limit)
        return BubbleCorners(
            topLeading: min(max(0, topLeading), limit),
            topTrailing: min(max(0, topTrailing), limit),
            bottomLeading: min(max(0, bottomLeading), limit),
            bottomTrailing: min(max(0, bottomTrailing), limit)
        )
    }
}
