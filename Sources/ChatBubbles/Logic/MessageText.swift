import Foundation

/// Turns a message's text into the attributed string a bubble shows.
public enum MessageText {
    /// Parses inline Markdown (`**bold**`, `*italic*`, `~~strike~~`, `` `code` ``, `[title](url)`)
    /// while keeping line breaks, then turns bare web addresses, like `https://example.com` or
    /// `www.example.com`, into links. Text that is not valid Markdown is shown as typed.
    public static func attributedString(
        from text: String,
        parsesMarkdown: Bool = true,
        detectsLinks: Bool = true
    ) -> AttributedString {
        var result = AttributedString(text)
        if parsesMarkdown,
           let parsed = try? AttributedString(
               markdown: text,
               options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
           ) {
            result = parsed
        }
        if detectsLinks {
            addLinks(to: &result)
        }
        return result
    }

    /// The links in `text` after parsing, in order.
    public static func links(in text: String) -> [URL] {
        attributedString(from: text).runs.compactMap { run in
            run[AttributeScopes.FoundationAttributes.LinkAttribute.self]
        }
    }

    private static func addLinks(to string: inout AttributedString) {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return
        }
        let plain = String(string.characters)
        let matches = detector.matches(in: plain, options: [], range: NSRange(plain.startIndex..., in: plain))
        for match in matches {
            guard let url = match.url, let range = Range(match.range, in: plain) else { continue }
            // Character offsets map the plain text back onto the attributed string.
            let offset = plain.distance(from: plain.startIndex, to: range.lowerBound)
            let length = plain.distance(from: range.lowerBound, to: range.upperBound)
            let characters = string.characters
            let start = characters.index(characters.startIndex, offsetBy: offset)
            let end = characters.index(start, offsetBy: length)
            let alreadyLinked = string[start..<end].runs.contains { run in
                run[AttributeScopes.FoundationAttributes.LinkAttribute.self] != nil
            }
            if !alreadyLinked {
                string[start..<end][AttributeScopes.FoundationAttributes.LinkAttribute.self] = url
            }
        }
    }
}

/// What the input bar sends.
public enum ChatComposer {
    /// The text without leading and trailing spaces and blank lines, or `nil` when nothing is left
    /// to send.
    public static func sendableText(from draft: String) -> String? {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

/// The motion of the typing indicator's dots, as a pure function of time.
public enum TypingAnimation {
    /// Seconds for one wave over the three dots.
    public static let period: Double = 1.2

    /// How far dot `index` (0, 1 or 2) is lifted at `time`, from 0 (resting) to 1 (top). Each dot
    /// rises and falls in the first half of its cycle and rests in the second, a little after the
    /// one before it.
    public static func lift(at time: TimeInterval, dot index: Int, period: Double = TypingAnimation.period) -> Double {
        guard period > 0 else { return 0 }
        var phase = (time / period - Double(index) * 0.18).truncatingRemainder(dividingBy: 1)
        if phase < 0 { phase += 1 }
        guard phase < 0.5 else { return 0 }
        return max(0, min(1, sin(phase * 2 * .pi)))
    }

    /// The fixed opacities used instead of motion when Reduce Motion is on.
    public static func staticOpacity(dot index: Int) -> Double {
        let opacities = [0.9, 0.65, 0.4]
        return opacities[min(max(index, 0), opacities.count - 1)]
    }
}
