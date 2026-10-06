import Foundation
import Testing
@testable import ChatBubbles

@Suite("Message text")
struct MessageTextTests {
    @Test func plainTextStaysAsTyped() {
        let text = MessageText.attributedString(from: "See you at 10")
        #expect(String(text.characters) == "See you at 10")
        #expect(MessageText.links(in: "See you at 10").isEmpty)
    }

    @Test func markdownIsParsedInline() {
        let text = MessageText.attributedString(from: "Ship it **today**")
        #expect(String(text.characters) == "Ship it today")
        let intents = text.runs.compactMap { $0.inlinePresentationIntent }
        #expect(intents.contains(.stronglyEmphasized))
    }

    @Test func lineBreaksAreKept() {
        let text = MessageText.attributedString(from: "One\nTwo")
        #expect(String(text.characters) == "One\nTwo")
    }

    @Test func markdownCanBeTurnedOff() {
        let text = MessageText.attributedString(from: "**raw**", parsesMarkdown: false)
        #expect(String(text.characters) == "**raw**")
    }

    @Test func bareURLsBecomeLinks() {
        let links = MessageText.links(in: "Notes at https://example.com/release and www.example.org")
        #expect(links.count == 2)
        #expect(links.first == URL(string: "https://example.com/release"))
        #expect(links.last?.host == "www.example.org")
    }

    @Test func linkDetectionCanBeTurnedOff() {
        let text = MessageText.attributedString(from: "https://example.com", detectsLinks: false)
        let links = text.runs.compactMap { $0[AttributeScopes.FoundationAttributes.LinkAttribute.self] }
        #expect(links.isEmpty)
    }

    @Test func markdownLinksKeepTheirTarget() {
        let links = MessageText.links(in: "Read [the notes](https://example.com/notes)")
        #expect(links == [URL(string: "https://example.com/notes")!])
    }

    @Test func linksAfterMarkdownLandOnTheRightCharacters() {
        let text = MessageText.attributedString(from: "**New:** https://example.com")
        #expect(String(text.characters) == "New: https://example.com")
        let linked = text.runs
            .filter { $0[AttributeScopes.FoundationAttributes.LinkAttribute.self] != nil }
            .map { String(text[$0.range].characters) }
        #expect(linked == ["https://example.com"])
    }
}

@Suite("Composer")
struct ChatComposerTests {
    @Test func trimsSpacesAndBlankLines() {
        #expect(ChatComposer.sendableText(from: "  Hello\n\n") == "Hello")
        #expect(ChatComposer.sendableText(from: "Line one\nLine two") == "Line one\nLine two")
    }

    @Test func nothingToSend() {
        #expect(ChatComposer.sendableText(from: "") == nil)
        #expect(ChatComposer.sendableText(from: "  \n\t ") == nil)
    }
}

@Suite("Reactions")
struct ChatReactionTests {
    private let reactions = [
        ChatReaction(emoji: "👍", count: 3, includesMe: false),
        ChatReaction(emoji: "🎉", count: 1, includesMe: true),
    ]

    @Test func addsMyReactionToAnExistingOne() {
        let result = ChatReaction.toggling("👍", in: reactions)
        #expect(result[0] == ChatReaction(emoji: "👍", count: 4, includesMe: true))
        #expect(result.count == 2)
    }

    @Test func takesMyReactionBack() {
        let added = ChatReaction.toggling("👍", in: reactions)
        let removed = ChatReaction.toggling("👍", in: added)
        #expect(removed == reactions)
    }

    @Test func removesAReactionNobodyHasAnyMore() {
        let result = ChatReaction.toggling("🎉", in: reactions)
        #expect(result.map(\.emoji) == ["👍"])
    }

    @Test func aNewEmojiGoesLast() {
        let result = ChatReaction.toggling("❤️", in: reactions)
        #expect(result.map(\.emoji) == ["👍", "🎉", "❤️"])
        #expect(result.last == ChatReaction(emoji: "❤️", count: 1, includesMe: true))
    }
}

@Suite("Participants")
struct ChatParticipantTests {
    @Test func initials() {
        #expect(ChatParticipant.initials(for: "Maya Chen") == "MC")
        #expect(ChatParticipant.initials(for: "leo") == "L")
        #expect(ChatParticipant.initials(for: "Sara van der Berg") == "SB")
        #expect(ChatParticipant.initials(for: "Jean-Luc Picard") == "JP")
        #expect(ChatParticipant.initials(for: "  ") == "?")
        #expect(ChatParticipant(id: "a", name: "Özge Kaya").initials == "ÖK")
    }
}

@Suite("Scrolling")
struct TranscriptChangeTests {
    @Test func detectsTheKindOfChange() {
        #expect(TranscriptChange.between([1, 2, 3], [1, 2, 3]) == .none)
        #expect(TranscriptChange.between([1, 2, 3], [1, 2, 3, 4]) == .appended)
        #expect(TranscriptChange.between([1, 2, 3], [-1, 0, 1, 2, 3]) == .prepended)
        #expect(TranscriptChange.between([Int](), [1, 2]) == .replaced)
        #expect(TranscriptChange.between([1, 2, 3], [7, 8, 9]) == .replaced)
        #expect(TranscriptChange.between([1, 2, 3], [1, 3]) == .replaced)
        #expect(TranscriptChange.between([1, 2], [0, 1, 2, 3]) == .replaced)
    }

    @Test func myOwnMessageAlwaysScrollsDown() {
        #expect(TranscriptChange.appended.scrollsToBottom(lastMessageIsOutgoing: true, isNearBottom: false))
    }

    @Test func othersOnlyScrollWhenIAmAtTheBottom() {
        #expect(TranscriptChange.appended.scrollsToBottom(lastMessageIsOutgoing: false, isNearBottom: true))
        #expect(!TranscriptChange.appended.scrollsToBottom(lastMessageIsOutgoing: false, isNearBottom: false))
    }

    @Test func olderMessagesKeepThePosition() {
        #expect(!TranscriptChange.prepended.scrollsToBottom(lastMessageIsOutgoing: true, isNearBottom: true))
        #expect(!TranscriptChange.none.scrollsToBottom(lastMessageIsOutgoing: true, isNearBottom: true))
        #expect(TranscriptChange.replaced.scrollsToBottom(lastMessageIsOutgoing: false, isNearBottom: false))
    }
}

@Suite("Typing animation")
struct TypingAnimationTests {
    @Test func theFirstDotPeaksAQuarterIntoTheWave() {
        #expect(abs(TypingAnimation.lift(at: TypingAnimation.period / 4, dot: 0) - 1) < 0.0001)
        #expect(TypingAnimation.lift(at: 0, dot: 0) < 0.0001)
        #expect(TypingAnimation.lift(at: TypingAnimation.period * 0.75, dot: 0) == 0)
    }

    @Test func laterDotsFollow() {
        let time = TypingAnimation.period / 4
        let first = TypingAnimation.lift(at: time, dot: 0)
        let second = TypingAnimation.lift(at: time, dot: 1)
        let third = TypingAnimation.lift(at: time, dot: 2)
        #expect(first > second)
        #expect(second > third)
    }

    @Test func liftStaysBetweenZeroAndOne() {
        for step in 0..<240 {
            for dot in 0..<3 {
                let lift = TypingAnimation.lift(at: Double(step) / 60, dot: dot)
                #expect(lift >= 0 && lift <= 1)
            }
        }
    }

    @Test func reduceMotionUsesFixedShades() {
        #expect(TypingAnimation.staticOpacity(dot: 0) > TypingAnimation.staticOpacity(dot: 1))
        #expect(TypingAnimation.staticOpacity(dot: 1) > TypingAnimation.staticOpacity(dot: 2))
        #expect(TypingAnimation.staticOpacity(dot: 9) == TypingAnimation.staticOpacity(dot: 2))
    }
}
