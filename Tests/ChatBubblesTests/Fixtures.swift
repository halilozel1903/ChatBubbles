import Foundation
@testable import ChatBubbles

enum Fixtures {
    /// Gregorian, UTC, so day boundaries do not depend on the machine running the tests.
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    static let locale = Locale(identifier: "en_US")

    /// Monday, October 5, 2026, 09:41 UTC.
    static let now = date(2026, 10, 5, 9, 41)

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    static func message(
        _ id: String,
        from sender: String,
        at date: Date,
        text: String = "Hello",
        status: DeliveryStatus = .sent
    ) -> SimpleMessage {
        SimpleMessage(id: id, senderID: sender, sentAt: date, text: text, status: status)
    }

    static var formatter: ChatDateFormatter {
        ChatDateFormatter(calendar: calendar, locale: locale, now: now)
    }

    static var grouping: MessageGrouping {
        MessageGrouping(currentUserID: "me", maximumGap: 5 * 60, calendar: calendar)
    }
}

extension String {
    /// Recent ICU versions put a narrow no-break space before "AM" and "PM".
    var normalizingSpaces: String {
        replacingOccurrences(of: "\u{202F}", with: " ").replacingOccurrences(of: "\u{00A0}", with: " ")
    }
}
