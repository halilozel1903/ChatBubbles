import Foundation
import Testing
@testable import ChatBubbles

@Suite("Message grouping")
struct MessageGroupingTests {
    private let grouping = Fixtures.grouping

    @Test func consecutiveMessagesFromOneSenderFormAGroup() {
        let messages = [
            Fixtures.message("1", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 0)),
            Fixtures.message("2", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 1)),
            Fixtures.message("3", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 2)),
        ]
        let positions = grouping.positions(for: messages)
        #expect(positions == [.first, .middle, .last])
    }

    @Test func aLoneMessageIsSingle() {
        let messages = [Fixtures.message("1", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 0))]
        let positions = grouping.positions(for: messages)
        #expect(positions == [.single])
        let none = grouping.positions(for: [SimpleMessage]())
        #expect(none.isEmpty)
    }

    @Test func anotherSenderStartsANewGroup() {
        let messages = [
            Fixtures.message("1", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 0)),
            Fixtures.message("2", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 1)),
            Fixtures.message("3", from: "me", at: Fixtures.date(2026, 10, 5, 9, 2)),
            Fixtures.message("4", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 3)),
        ]
        let positions = grouping.positions(for: messages)
        #expect(positions == [.first, .last, .single, .single])
    }

    @Test func aLongPauseStartsANewGroup() {
        let messages = [
            Fixtures.message("1", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 0)),
            Fixtures.message("2", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 5)),    // exactly 5 minutes: same group
            Fixtures.message("3", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 11)),   // 6 minutes: new group
        ]
        let positions = grouping.positions(for: messages)
        #expect(positions == [.first, .last, .single])
    }

    @Test func theGapIsConfigurable() {
        let messages = [
            Fixtures.message("1", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 0)),
            Fixtures.message("2", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 20)),
        ]
        let wide = MessageGrouping(currentUserID: "me", maximumGap: 30 * 60, calendar: Fixtures.calendar)
        let widePositions = wide.positions(for: messages)
        #expect(widePositions == [.first, .last])
        let narrowPositions = grouping.positions(for: messages)
        #expect(narrowPositions == [.single, .single])
    }

    @Test func midnightSplitsAGroup() {
        let messages = [
            Fixtures.message("1", from: "maya", at: Fixtures.date(2026, 10, 4, 23, 59)),
            Fixtures.message("2", from: "maya", at: Fixtures.date(2026, 10, 5, 0, 1)),
        ]
        let positions = grouping.positions(for: messages)
        #expect(positions == [.single, .single])
    }

    @Test func messagesOutOfOrderDoNotJoin() {
        let messages = [
            Fixtures.message("1", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 3)),
            Fixtures.message("2", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 1)),
        ]
        let joins = grouping.continues(messages[1], after: messages[0])
        #expect(joins == false)
    }

    @Test func itemsHaveADaySeparatorBeforeEachDay() {
        let messages = [
            Fixtures.message("1", from: "maya", at: Fixtures.date(2026, 10, 4, 17, 0)),
            Fixtures.message("2", from: "me", at: Fixtures.date(2026, 10, 4, 17, 2)),
            Fixtures.message("3", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 0)),
        ]
        let items = grouping.items(for: messages)
        let days = items.compactMap(\.day)
        #expect(days == [Fixtures.date(2026, 10, 4, 0, 0), Fixtures.date(2026, 10, 5, 0, 0)])
        #expect(items.count == 5)
        #expect(items[0].day != nil)
        #expect(items[1].message?.id == "1")
        #expect(items[3].day != nil)
        #expect(items[4].message?.id == "3")
    }

    @Test func daySeparatorsCanBeTurnedOff() {
        var grouping = Fixtures.grouping
        grouping.showsDaySeparators = false
        let messages = [
            Fixtures.message("1", from: "maya", at: Fixtures.date(2026, 10, 4, 17, 0)),
            Fixtures.message("2", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 0)),
        ]
        let items = grouping.items(for: messages)
        #expect(items.allSatisfy { $0.message != nil })
    }

    @Test func aDayIsNeverSeparatedTwice() {
        let messages = [
            Fixtures.message("1", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 0)),
            Fixtures.message("2", from: "maya", at: Fixtures.date(2026, 10, 4, 9, 0)),
            Fixtures.message("3", from: "maya", at: Fixtures.date(2026, 10, 5, 10, 0)),
        ]
        let items = grouping.items(for: messages)
        let ids = items.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(items.compactMap(\.day).count == 2)
    }

    @Test func sidesFollowTheCurrentUser() {
        let messages = [
            Fixtures.message("1", from: "me", at: Fixtures.date(2026, 10, 5, 9, 0)),
            Fixtures.message("2", from: "leo", at: Fixtures.date(2026, 10, 5, 9, 1)),
        ]
        let entries = grouping.items(for: messages).compactMap(\.message)
        #expect(entries.map(\.isOutgoing) == [true, false])
    }

    @Test func theLastBubbleOfAGroupShowsTheTime() {
        let messages = [
            Fixtures.message("1", from: "leo", at: Fixtures.date(2026, 10, 5, 9, 0)),
            Fixtures.message("2", from: "leo", at: Fixtures.date(2026, 10, 5, 9, 1)),
            Fixtures.message("3", from: "maya", at: Fixtures.date(2026, 10, 5, 9, 2)),
        ]
        let entries = grouping.items(for: messages).compactMap(\.message)
        #expect(entries.map(\.showsTimestamp) == [false, true, true])
    }

    @Test func onlyTheLatestOutgoingMessageShowsItsStatus() {
        let messages = [
            Fixtures.message("1", from: "me", at: Fixtures.date(2026, 10, 5, 9, 0), status: .read()),
            Fixtures.message("2", from: "me", at: Fixtures.date(2026, 10, 5, 9, 1), status: .delivered),
            Fixtures.message("3", from: "leo", at: Fixtures.date(2026, 10, 5, 9, 2)),
        ]
        let entries = grouping.items(for: messages).compactMap(\.message)
        #expect(entries.map(\.showsStatus) == [false, true, false])
    }

    @Test func failedMessagesAlwaysShowTheirStatus() {
        let messages = [
            Fixtures.message("1", from: "me", at: Fixtures.date(2026, 10, 5, 9, 0), status: .failed),
            Fixtures.message("2", from: "me", at: Fixtures.date(2026, 10, 5, 9, 1), status: .sent),
        ]
        let entries = grouping.items(for: messages).compactMap(\.message)
        #expect(entries.map(\.showsStatus) == [true, true])
    }

    @Test func positionsDecideTailsNamesAndAvatars() {
        #expect(BubblePosition.single.isGroupStart && BubblePosition.single.isGroupEnd)
        #expect(BubblePosition.first.isGroupStart && !BubblePosition.first.isGroupEnd)
        #expect(!BubblePosition.middle.isGroupStart && !BubblePosition.middle.isGroupEnd)
        #expect(!BubblePosition.last.isGroupStart && BubblePosition.last.isGroupEnd)
    }

    @Test func customMessageTypesUseTheDefaults() {
        struct Note: ChatMessage {
            let id: Int
            let senderID: String
            let sentAt: Date
            let text: String
        }
        let note = Note(id: 1, senderID: "me", sentAt: Fixtures.now, text: "Hi")
        #expect(note.attachment == nil)
        #expect(note.reply == nil)
        #expect(note.reactions.isEmpty)
        #expect(note.status == .sent)
        let items = grouping.items(for: [note])
        #expect(items.last?.message?.showsStatus == true)
    }
}
