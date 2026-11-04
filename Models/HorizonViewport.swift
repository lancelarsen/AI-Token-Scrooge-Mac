import Foundation

/// Equal-width calendar-day geometry, with actual elapsed time inside each day.
/// A 23/25-hour DST day occupies the same width without merging repeated clock times.
struct HorizonViewport: Sendable {
    private(set) var now: Date
    private(set) var zone: TimeZone
    private(set) var viewportWidth: Double
    private(set) var historyEnabled: Bool
    private(set) var pixelsPerDay: Double = 80
    private(set) var startCoordinate: Double = 0
    private(set) var endCoordinate: Double = 1
    private(set) var scrollOffset: Double = 0
    private(set) var followingToday = true
    private(set) var lastEventAt: Date
    private var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = zone; return c }
    var contentWidth: Double { (endCoordinate - startCoordinate) * pixelsPerDay }
    var maximumScrollOffset: Double { max(0, contentWidth - viewportWidth) }
    var visibleDays: Double { viewportWidth / pixelsPerDay }
    var visibleStart: Date { date(at: scrollOffset) }
    var todayStart: Date { calendar.startOfDay(for: now) }
    var firstDate: Date { calendar.startOfDay(for: date(at: 0)) }

    init(now: Date, furthestFuture: Date?, zone: TimeZone, width: Double, historyEnabled: Bool = true, earliestHistory: Date? = nil) {
        self.now = now; self.zone = zone; viewportWidth = max(1, width.isFinite ? width : 1)
        self.historyEnabled = historyEnabled; lastEventAt = max(now, furthestFuture ?? now)
        configure(earliestHistory: earliestHistory); followToday()
    }
    mutating func update(now: Date, furthestFuture: Date?, zone: TimeZone, width: Double, historyEnabled: Bool, earliestHistory: Date? = nil) {
        let left = visibleStart
        let changed = self.historyEnabled != historyEnabled
        self.now = now; self.zone = zone; viewportWidth = max(1, width.isFinite ? width : 1)
        self.historyEnabled = historyEnabled; lastEventAt = max(now, furthestFuture ?? now)
        configure(earliestHistory: earliestHistory)
        if changed || followingToday { followToday() } else { scrollOffset = clamp(position(at: left)) }
    }
    private mutating func configure(earliestHistory: Date?) {
        let today = coordinate(todayStart)
        let futureEnd = floor(coordinate(lastEventAt)) + 1
        if historyEnabled {
            var first = calendar.date(byAdding: .day, value: -7, to: now)!
            if let earliestHistory { first = max(first, min(now, earliestHistory)) }
            startCoordinate = coordinate(first)
            pixelsPerDay = max(80, viewportWidth / max(1, max(coordinate(now) - startCoordinate, futureEnd - today)))
            endCoordinate = today + max(futureEnd - today, visibleDays)
        } else {
            startCoordinate = today; endCoordinate = futureEnd
            pixelsPerDay = max(80, viewportWidth / max(1, endCoordinate - startCoordinate))
        }
    }
    mutating func followToday() { followingToday = true; scrollOffset = historyEnabled ? clamp(position(at: todayStart)) : 0 }
    mutating func scroll(to offset: Double) {
        guard !offset.isNaN else { return }
        scrollOffset = clamp(offset)
        followingToday = abs(scrollOffset - (historyEnabled ? clamp(position(at: todayStart)) : 0)) < 0.5
    }
    func position(at instant: Date) -> Double { (coordinate(instant) - startCoordinate) * pixelsPerDay }
    func dayAnchor(_ date: Date) -> Double { position(at: calendar.startOfDay(for: date)) + pixelsPerDay / 2 }
    func showsFutureEvents(on date: Date) -> Bool {
        let x = dayAnchor(date)
        let left = max(scrollOffset, position(at: now))
        return x >= left - 24 && x <= scrollOffset + viewportWidth + 12
    }
    func date(at contentX: Double) -> Date { fromCoordinate(startCoordinate + min(contentWidth, max(0, contentX.isFinite ? contentX : 0)) / pixelsPerDay) }
    func overview(trackWidth: Double) -> (left: Double, width: Double) {
        let track = max(0, trackWidth.isFinite ? trackWidth : 0)
        return (scrollOffset / contentWidth * track, min(1, viewportWidth / contentWidth) * track)
    }
    mutating func centerFromOverview(pointerX: Double, trackWidth: Double) {
        guard pointerX.isFinite, trackWidth.isFinite, trackWidth > 0 else { return }
        scroll(to: pointerX / trackWidth * contentWidth - viewportWidth / 2)
    }
    mutating func dragOverview(startOffset: Double, translation: Double, trackWidth: Double) {
        guard startOffset.isFinite, translation.isFinite, trackWidth.isFinite, trackWidth > 0 else { return }
        scroll(to: startOffset + translation / trackWidth * contentWidth)
    }
    private func clamp(_ value: Double) -> Double { min(maximumScrollOffset, max(0, value)) }
    private func dayNumber(_ date: Date) -> Int {
        // Use a UTC civil calendar to number local dates without accumulating DST offsets.
        var utc = Calendar(identifier: .gregorian); utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return Int(utc.date(from: parts)!.timeIntervalSince1970 / 86400)
    }
    private func coordinate(_ instant: Date) -> Double {
        let start = calendar.startOfDay(for: instant)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return Double(dayNumber(instant)) + instant.timeIntervalSince(start) / end.timeIntervalSince(start)
    }
    private func fromCoordinate(_ value: Double) -> Date {
        var utc = Calendar(identifier: .gregorian); utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let parts = utc.dateComponents([.year, .month, .day], from: Date(timeIntervalSince1970: floor(value) * 86400))
        let start = calendar.startOfDay(for: calendar.date(from: parts)!)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return start.addingTimeInterval((value - floor(value)) * end.timeIntervalSince(start))
    }
}
