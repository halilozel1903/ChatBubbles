import Foundation

/// The texts of day separators, timestamps and delivery receipts.
///
/// Everything that depends on the clock or the region is injected, so the same messages always give
/// the same texts in previews, screenshots and tests:
///
/// ```swift
/// var calendar = Calendar(identifier: .gregorian)
/// calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!
/// let formatter = ChatDateFormatter(calendar: calendar, locale: Locale(identifier: "en_US"), now: now)
///
/// formatter.dayTitle(for: now)                    // "Today"
/// formatter.dayTitle(for: threeDaysAgo)           // "Friday"
/// formatter.dayTitle(for: lastMonth)              // "Wed, Sep 2"
/// formatter.time(for: now)                        // "9:41 AM"
/// formatter.receipt(for: .read(at: now))          // "Read 9:41 AM"
/// ```
public struct ChatDateFormatter: Sendable {
    public var calendar: Calendar
    public var locale: Locale
    /// The current moment; "Today" is the day that contains it.
    public var now: Date
    /// The words for today and yesterday. Change them to localize.
    public var todayTitle: String
    public var yesterdayTitle: String

    public init(
        calendar: Calendar = .current,
        locale: Locale = .current,
        now: Date = .now,
        todayTitle: String = "Today",
        yesterdayTitle: String = "Yesterday"
    ) {
        self.calendar = calendar
        self.locale = locale
        self.now = now
        self.todayTitle = todayTitle
        self.yesterdayTitle = yesterdayTitle
    }

    /// Whole days from the day of `date` to today: 0 for today, 1 for yesterday, negative for the
    /// future. Counts calendar days, so 23:59 yesterday is 1 day ago at 00:01 today.
    public func daysAgo(_ date: Date) -> Int {
        let day = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: day, to: today).day ?? 0
    }

    /// "Today", "Yesterday", the weekday within the last week ("Monday"), the date without the year
    /// in the current year ("Mon, Sep 14"), or with the year before that ("Sep 14, 2025").
    public func dayTitle(for date: Date) -> String {
        let days = daysAgo(date)
        switch days {
        case 0:
            return todayTitle
        case 1:
            return yesterdayTitle
        case 2...6:
            return format(date, template: "EEEE")
        default:
            if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
                return format(date, template: "EEEMMMd")
            }
            return format(date, template: "yMMMd")
        }
    }

    /// The time of day in the locale's style: "9:41 AM" in the US, "09:41" in Germany.
    public func time(for date: Date) -> String {
        format(date, template: "jmm")
    }

    /// The text under the latest outgoing message: "Sending…", "Sent", "Delivered", "Read",
    /// "Read 9:41 AM" (today) or "Read Yesterday" (earlier), or "Not delivered".
    public func receipt(for status: DeliveryStatus) -> String {
        switch status {
        case .sending:
            return "Sending…"
        case .sent:
            return "Sent"
        case .delivered:
            return "Delivered"
        case .read(let date):
            guard let date else { return "Read" }
            return daysAgo(date) == 0 ? "Read \(time(for: date))" : "Read \(dayTitle(for: date))"
        case .failed:
            return "Not delivered"
        }
    }

    private func format(_ date: Date, template: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }
}
