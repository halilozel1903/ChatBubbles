import Foundation
import Testing
@testable import ChatBubbles

@Suite("Day separators, times and receipts")
struct ChatDateFormatterTests {
    private let formatter = Fixtures.formatter

    @Test func todayAndYesterday() {
        #expect(formatter.dayTitle(for: Fixtures.date(2026, 10, 5, 0, 0)) == "Today")
        #expect(formatter.dayTitle(for: Fixtures.date(2026, 10, 5, 23, 59)) == "Today")
        #expect(formatter.dayTitle(for: Fixtures.date(2026, 10, 4, 23, 59)) == "Yesterday")
        #expect(formatter.dayTitle(for: Fixtures.date(2026, 10, 4, 0, 0)) == "Yesterday")
    }

    @Test func weekdaysWithinTheLastWeek() {
        #expect(formatter.dayTitle(for: Fixtures.date(2026, 10, 3)) == "Saturday")
        #expect(formatter.dayTitle(for: Fixtures.date(2026, 9, 29)) == "Tuesday")
    }

    @Test func datesBeforeThat() {
        #expect(formatter.dayTitle(for: Fixtures.date(2026, 9, 28)) == "Mon, Sep 28")
        #expect(formatter.dayTitle(for: Fixtures.date(2025, 9, 14)) == "Sep 14, 2025")
    }

    @Test func futureDaysShowTheDate() {
        #expect(formatter.daysAgo(Fixtures.date(2026, 10, 6)) == -1)
        #expect(formatter.dayTitle(for: Fixtures.date(2026, 10, 6)) == "Tue, Oct 6")
    }

    @Test func daysAgoCountsCalendarDays() {
        #expect(formatter.daysAgo(Fixtures.date(2026, 10, 4, 23, 59)) == 1)
        #expect(formatter.daysAgo(Fixtures.now) == 0)
        #expect(formatter.daysAgo(Fixtures.date(2026, 9, 5, 9, 41)) == 30)
    }

    @Test func titlesCanBeLocalized() {
        let turkish = ChatDateFormatter(
            calendar: Fixtures.calendar,
            locale: Locale(identifier: "tr_TR"),
            now: Fixtures.now,
            todayTitle: "Bugün",
            yesterdayTitle: "Dün"
        )
        #expect(turkish.dayTitle(for: Fixtures.now) == "Bugün")
        #expect(turkish.dayTitle(for: Fixtures.date(2026, 10, 4)) == "Dün")
        #expect(turkish.dayTitle(for: Fixtures.date(2026, 10, 3)) == "Cumartesi")
    }

    @Test func theTimeZoneComesFromTheCalendar() {
        var istanbul = Fixtures.calendar
        istanbul.timeZone = TimeZone(identifier: "Europe/Istanbul")!          // UTC+3
        let formatter = ChatDateFormatter(calendar: istanbul, locale: Fixtures.locale, now: Fixtures.now)
        // 22:30 UTC on October 4 is 01:30 on October 5 in Istanbul.
        #expect(formatter.dayTitle(for: Fixtures.date(2026, 10, 4, 22, 30)) == "Today")
        #expect(formatter.time(for: Fixtures.date(2026, 10, 4, 22, 30)).normalizingSpaces == "1:30 AM")
    }

    @Test func timesFollowTheLocale() {
        #expect(formatter.time(for: Fixtures.now).normalizingSpaces == "9:41 AM")
        let german = ChatDateFormatter(calendar: Fixtures.calendar, locale: Locale(identifier: "de_DE"), now: Fixtures.now)
        #expect(german.time(for: Fixtures.now) == "09:41")
    }

    @Test func receipts() {
        #expect(formatter.receipt(for: .sending) == "Sending…")
        #expect(formatter.receipt(for: .sent) == "Sent")
        #expect(formatter.receipt(for: .delivered) == "Delivered")
        #expect(formatter.receipt(for: .read()) == "Read")
        #expect(formatter.receipt(for: .read(at: Fixtures.date(2026, 10, 5, 9, 40))).normalizingSpaces == "Read 9:40 AM")
        #expect(formatter.receipt(for: .read(at: Fixtures.date(2026, 10, 4, 18, 0))) == "Read Yesterday")
        #expect(formatter.receipt(for: .failed) == "Not delivered")
    }

    @Test func readStatus() {
        #expect(DeliveryStatus.read().isRead)
        #expect(DeliveryStatus.read(at: Fixtures.now).isRead)
        #expect(!DeliveryStatus.delivered.isRead)
    }
}
