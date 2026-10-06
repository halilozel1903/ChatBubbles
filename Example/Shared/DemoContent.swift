import ChatBubbles
import SwiftUI

/// A conversation in the sidebar or the chat list.
struct DemoChat: Identifiable, Hashable {
    let id: String
    let title: String
    /// The other people in the chat.
    let memberIDs: [String]
    /// The icon of a group chat.
    let symbol: String
    let color: Color
    let unreadCount: Int

    var isGroup: Bool { memberIDs.count > 1 }

    /// "4 members" for groups, nothing for one-to-one chats.
    var subtitle: String? {
        isGroup ? "\(memberIDs.count + 1) members" : nil
    }
}

/// Huddle, a made-up team chat: the Atlas team getting version 2.0 out of the door.
enum DemoContent {
    static let me = ChatParticipant(id: "me", name: "Alex Rivera", color: Color(red: 0.0, green: 0.48, blue: 1.0))
    static let maya = ChatParticipant(id: "maya", name: "Maya Chen", color: Color(red: 0.89, green: 0.27, blue: 0.53))
    static let leo = ChatParticipant(id: "leo", name: "Leo Park", color: Color(red: 0.95, green: 0.50, blue: 0.13))
    static let sara = ChatParticipant(id: "sara", name: "Sara Ito", color: Color(red: 0.10, green: 0.62, blue: 0.62))
    static let nina = ChatParticipant(id: "nina", name: "Nina Duarte", color: Color(red: 0.45, green: 0.36, blue: 0.86))

    /// Everyone except the current user.
    static let people = [maya, leo, sara, nina]

    static let launchCrewID = "launch-crew"

    static let chats = [
        DemoChat(id: launchCrewID, title: "Launch Crew", memberIDs: ["maya", "leo", "sara"], symbol: "paperplane.fill",
                 color: Color(red: 0.0, green: 0.48, blue: 1.0), unreadCount: 0),
        DemoChat(id: "design-reviews", title: "Design Reviews", memberIDs: ["maya", "nina"], symbol: "paintpalette.fill",
                 color: Color(red: 0.89, green: 0.27, blue: 0.53), unreadCount: 3),
        DemoChat(id: "leo", title: "Leo Park", memberIDs: ["leo"], symbol: "person.fill",
                 color: Color(red: 0.95, green: 0.50, blue: 0.13), unreadCount: 1),
        DemoChat(id: "sara", title: "Sara Ito", memberIDs: ["sara"], symbol: "person.fill",
                 color: Color(red: 0.10, green: 0.62, blue: 0.62), unreadCount: 0),
        DemoChat(id: "random", title: "Random", memberIDs: ["maya", "leo", "sara", "nina"], symbol: "cup.and.saucer.fill",
                 color: Color(red: 0.45, green: 0.36, blue: 0.86), unreadCount: 0),
    ]

    static func participant(withID id: String) -> ChatParticipant? {
        people.first { $0.id == id }
    }

    // MARK: - Fixed clock for screenshots

    /// Gregorian, UTC: the same days and times on every machine.
    static let screenshotCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    static let screenshotLocale = Locale(identifier: "en_US")

    /// Monday, October 5, 2026, 9:41 AM.
    static let screenshotNow = screenshotCalendar.date(
        from: DateComponents(year: 2026, month: 10, day: 5, hour: 9, minute: 41)
    )!

    // MARK: - Messages

    /// A date `days` days before `now`'s day, at `hour`:`minute`.
    private struct Clock {
        let now: Date
        let calendar: Calendar

        func at(_ days: Int, _ hour: Int, _ minute: Int) -> Date {
            let today = calendar.startOfDay(for: now)
            let day = calendar.date(byAdding: .day, value: -days, to: today) ?? today
            return calendar.date(byAdding: .minute, value: hour * 60 + minute, to: day) ?? day
        }
    }

    /// The conversation of every screenshot: yesterday's checklist and launch graphic, then this
    /// morning's TestFlight build, a decision and a read receipt.
    static func launchCrew(now: Date, calendar: Calendar) -> [SimpleMessage] {
        let clock = Clock(now: now, calendar: calendar)
        return [
            SimpleMessage(id: "lc-1", senderID: "sara", sentAt: clock.at(1, 17, 2),
                          text: "The release checklist for **Atlas 2.0** is in the shared doc. Please have a look before tomorrow."),
            SimpleMessage(id: "lc-2", senderID: "leo", sentAt: clock.at(1, 17, 5), text: "On it 👍"),
            SimpleMessage(id: "lc-3", senderID: "me", sentAt: clock.at(1, 17, 20),
                          text: "Looks good. I added the App Store screenshots to the list."),
            SimpleMessage(id: "lc-4", senderID: "maya", sentAt: clock.at(1, 17, 48),
                          attachment: .image(name: "LaunchBoard", aspectRatio: 4.0 / 3.0, description: "The Atlas 2.0 launch graphic: a phone on an orange and pink gradient"),
                          reactions: [ChatReaction(emoji: "🔥", count: 3, includesMe: true), ChatReaction(emoji: "😍", count: 1)]),
            SimpleMessage(id: "lc-5", senderID: "maya", sentAt: clock.at(1, 17, 49), text: "Final launch graphic 🎨"),

            SimpleMessage(id: "lc-6", senderID: "maya", sentAt: clock.at(0, 9, 2),
                          text: "Morning! Build 2.0 (418) is on TestFlight."),
            SimpleMessage(id: "lc-7", senderID: "maya", sentAt: clock.at(0, 9, 3),
                          text: "Release notes: **dark mode**, offline drafts and a *much* faster search. https://atlas.example.com/2.0"),
            SimpleMessage(id: "lc-8", senderID: "leo", sentAt: clock.at(0, 9, 10),
                          text: "Crash-free sessions are at 99.98% after the first 1,200 testers.",
                          reactions: [ChatReaction(emoji: "🎉", count: 2)]),
            SimpleMessage(id: "lc-9", senderID: "me", sentAt: clock.at(0, 9, 14), text: "That's the best beta we've had."),
            SimpleMessage(id: "lc-10", senderID: "me", sentAt: clock.at(0, 9, 15), text: "Let's ship it on Thursday 🚀",
                          reactions: [ChatReaction(emoji: "👍", count: 3), ChatReaction(emoji: "❤️", count: 1)]),
            SimpleMessage(id: "lc-11", senderID: "sara", sentAt: clock.at(0, 9, 31),
                          text: "Thursday works. I'll book the 10:00 review with marketing."),
            SimpleMessage(id: "lc-12", senderID: "me", sentAt: clock.at(0, 9, 38), text: "Perfect, see you all there.",
                          status: .read(at: clock.at(0, 9, 40))),
        ]
    }

    /// The reply of the `typing` screenshot: quotes Leo's numbers while he is typing.
    static func launchCrewReply(now: Date, calendar: Calendar) -> SimpleMessage {
        let clock = Clock(now: now, calendar: calendar)
        return SimpleMessage(
            id: "lc-13",
            senderID: "me",
            sentAt: clock.at(0, 9, 40),
            text: "Can you share that dashboard with marketing too?",
            reply: ChatReply(messageID: "lc-8", senderName: "Leo Park", text: "Crash-free sessions are at 99.98% after the first 1,200 testers."),
            status: .delivered
        )
    }

    /// Older Launch Crew messages, loaded a page at a time when you scroll to the top. The last page
    /// is loaded first.
    static func launchCrewOlderPages(now: Date, calendar: Calendar) -> [[SimpleMessage]] {
        let clock = Clock(now: now, calendar: calendar)
        return [
            [
                SimpleMessage(id: "old-1", senderID: "sara", sentAt: clock.at(4, 10, 0), text: "Kickoff for 2.0 is on the calendar 🗓️"),
                SimpleMessage(id: "old-2", senderID: "maya", sentAt: clock.at(4, 10, 6), text: "I'll bring the new onboarding flow."),
                SimpleMessage(id: "old-3", senderID: "me", sentAt: clock.at(4, 10, 9), text: "Great, I'll write up the scope."),
            ],
            [
                SimpleMessage(id: "old-4", senderID: "leo", sentAt: clock.at(3, 15, 30), text: "Offline drafts are merged."),
                SimpleMessage(id: "old-5", senderID: "leo", sentAt: clock.at(3, 15, 31), text: "Sync conflicts keep both versions for now."),
                SimpleMessage(id: "old-6", senderID: "me", sentAt: clock.at(3, 15, 40), text: "Perfect for 2.0, let's revisit in 2.1.",
                              reactions: [ChatReaction(emoji: "👍", count: 2)]),
                SimpleMessage(id: "old-7", senderID: "sara", sentAt: clock.at(2, 11, 15), text: "Marketing wants the launch on a Thursday."),
            ],
        ]
    }

    /// Short conversations for the other chats.
    static func otherChats(now: Date, calendar: Calendar) -> [String: [SimpleMessage]] {
        let clock = Clock(now: now, calendar: calendar)
        return [
            "design-reviews": [
                SimpleMessage(id: "dr-1", senderID: "nina", sentAt: clock.at(1, 14, 0), text: "New icon options are up in Figma."),
                SimpleMessage(id: "dr-2", senderID: "me", sentAt: clock.at(1, 14, 20), text: "Option B reads best at small sizes."),
                SimpleMessage(id: "dr-3", senderID: "maya", sentAt: clock.at(0, 8, 50), text: "Agreed, B it is. Exporting all sizes now."),
            ],
            "leo": [
                SimpleMessage(id: "leo-1", senderID: "me", sentAt: clock.at(0, 8, 30), text: "Can you check the TestFlight crash from last night?"),
                SimpleMessage(id: "leo-2", senderID: "leo", sentAt: clock.at(0, 9, 22), text: "Fixed in 418, it was the widget timeline."),
            ],
            "sara": [
                SimpleMessage(id: "sara-1", senderID: "sara", sentAt: clock.at(2, 16, 10), text: "Thanks for covering the review!"),
                SimpleMessage(id: "sara-2", senderID: "me", sentAt: clock.at(2, 16, 12), text: "Anytime 🙌", status: .read()),
            ],
            "random": [
                SimpleMessage(id: "rnd-1", senderID: "leo", sentAt: clock.at(1, 12, 30), text: "Lunch at the taco place?"),
                SimpleMessage(id: "rnd-2", senderID: "nina", sentAt: clock.at(1, 12, 31), text: "Always 🌮"),
            ],
        ]
    }

    /// What someone answers in the live demo.
    static let replies = [
        "Sounds good!",
        "On it 👍",
        "Let me check and get back to you.",
        "Love it 🎉",
        "Can we talk about it at standup?",
    ]
}
