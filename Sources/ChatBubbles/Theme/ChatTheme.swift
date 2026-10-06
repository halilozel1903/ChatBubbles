import SwiftUI

/// Colors, fonts and metrics of every ChatBubbles view.
///
/// ```swift
/// ChatView(messages: messages, currentUserID: "me")
///     .chatTheme(.graphite)
///
/// var theme = ChatTheme.default
/// theme.outgoingBackground = .purple
/// theme.cornerRadius = 22
/// ```
public struct ChatTheme: Sendable {
    /// Your own bubbles.
    public var outgoingBackground: Color
    public var outgoingForeground: Color
    /// Other people's bubbles and the typing indicator.
    public var incomingBackground: Color
    public var incomingForeground: Color
    /// The send button, links in incoming bubbles, the reply bar and your own reactions.
    public var accent: Color
    /// Reaction chips that do not include you.
    public var reactionBackground: Color
    /// The text field of the input bar.
    public var inputBackground: Color
    /// The message text.
    public var font: Font
    /// Day separators, names, timestamps and receipts.
    public var metadataFont: Font
    public var metadataColor: Color
    /// The radius of a bubble's free corners.
    public var cornerRadius: CGFloat
    /// The radius where bubbles of one group touch.
    public var groupedCornerRadius: CGFloat
    /// Whether the last bubble of a group has a tail.
    public var showsTails: Bool
    /// How far the tail reaches out of the bubble. The space is kept even without a tail, so all
    /// bubbles of a side line up.
    public var tailWidth: CGFloat
    /// The widest a bubble gets, for wide windows on the Mac and iPad.
    public var maximumBubbleWidth: CGFloat
    /// Space between bubbles of one group.
    public var bubbleSpacing: CGFloat
    /// Space between groups.
    public var groupSpacing: CGFloat

    public init(
        outgoingBackground: Color = Color(red: 0.0, green: 0.48, blue: 1.0),
        outgoingForeground: Color = .white,
        incomingBackground: Color = .adaptive(
            light: Color(red: 0.91, green: 0.91, blue: 0.93),
            dark: Color(red: 0.17, green: 0.17, blue: 0.19)
        ),
        incomingForeground: Color = .primary,
        accent: Color = Color(red: 0.0, green: 0.48, blue: 1.0),
        reactionBackground: Color = .adaptive(
            light: Color(red: 0.97, green: 0.97, blue: 0.98),
            dark: Color(red: 0.24, green: 0.24, blue: 0.26)
        ),
        inputBackground: Color = .adaptive(
            light: .white,
            dark: Color(red: 0.11, green: 0.11, blue: 0.12)
        ),
        font: Font = .body,
        metadataFont: Font = .caption2,
        metadataColor: Color = .secondary,
        cornerRadius: CGFloat = 18,
        groupedCornerRadius: CGFloat = 5,
        showsTails: Bool = true,
        tailWidth: CGFloat = 6,
        maximumBubbleWidth: CGFloat = 520,
        bubbleSpacing: CGFloat = 2,
        groupSpacing: CGFloat = 12
    ) {
        self.outgoingBackground = outgoingBackground
        self.outgoingForeground = outgoingForeground
        self.incomingBackground = incomingBackground
        self.incomingForeground = incomingForeground
        self.accent = accent
        self.reactionBackground = reactionBackground
        self.inputBackground = inputBackground
        self.font = font
        self.metadataFont = metadataFont
        self.metadataColor = metadataColor
        self.cornerRadius = cornerRadius
        self.groupedCornerRadius = groupedCornerRadius
        self.showsTails = showsTails
        self.tailWidth = tailWidth
        self.maximumBubbleWidth = maximumBubbleWidth
        self.bubbleSpacing = bubbleSpacing
        self.groupSpacing = groupSpacing
    }

    /// Blue bubbles with tails, like Messages.
    public static let `default` = ChatTheme()

    /// Dark gray bubbles with an orange accent and softer corners.
    public static let graphite = ChatTheme(
        outgoingBackground: .adaptive(
            light: Color(red: 0.20, green: 0.21, blue: 0.24),
            dark: Color(red: 0.36, green: 0.37, blue: 0.41)
        ),
        accent: Color(red: 0.96, green: 0.52, blue: 0.15),
        cornerRadius: 14,
        groupedCornerRadius: 4
    )

    /// Green bubbles without tails and with round corners everywhere.
    public static let meadow = ChatTheme(
        outgoingBackground: Color(red: 0.13, green: 0.62, blue: 0.40),
        accent: Color(red: 0.13, green: 0.62, blue: 0.40),
        cornerRadius: 20,
        groupedCornerRadius: 20,
        showsTails: false
    )
}

private struct ChatThemeKey: EnvironmentKey {
    static let defaultValue = ChatTheme.default
}

extension EnvironmentValues {
    /// The theme of the ChatBubbles views below.
    public var chatTheme: ChatTheme {
        get { self[ChatThemeKey.self] }
        set { self[ChatThemeKey.self] = newValue }
    }
}

extension View {
    /// Sets the theme of the ChatBubbles views in this view.
    public func chatTheme(_ theme: ChatTheme) -> some View {
        environment(\.chatTheme, theme)
    }
}

extension Color {
    /// A color with one value in light mode and another in dark mode.
    public static func adaptive(light: Color, dark: Color) -> Color {
        #if canImport(UIKit)
        return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        return Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? NSColor(dark) : NSColor(light)
        })
        #else
        return light
        #endif
    }
}
