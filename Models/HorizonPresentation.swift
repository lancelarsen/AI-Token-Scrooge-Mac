import Foundation

/// Prepared only when history, accounts, or projection geometry changes.
/// Scrolling reads these results without sorting observations or doing calendar
/// conversions again for every point on every frame.
struct HorizonPresentation {
    var series: [UsageHistorySeries] = []
    var events: [HorizonEvent] = []
    var renderPoints: [String: [HistoryPoint]] = [:]
    var positions: [Date: Double] = [:]
    init() {}
    init(accounts: [ProviderAccount], runs: [HistoryRun], viewport: HorizonViewport, now: Date) {
        // Keep the source history independent of navigation and History on/off.
        // Otherwise narrowing the viewport also loses the samples needed to reopen it.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = viewport.zone
        let from = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -7, to: now)!)
        let runsByAccount = Dictionary(grouping: runs, by: \.snapshot.accountID)
        for account in accounts {
            let accountRuns = runsByAccount[account.id] ?? []
            series.append(UsageHistory.build(account: account, runs: accountRuns, from: from, through: now))
            events.append(contentsOf: UsageHistory.events(account: account, runs: accountRuns, from: from, through: now))
        }
        for date in Set(series.flatMap { $0.points.map(\.at) } + events.map(\.date)) {
            positions[date] = viewport.position(at: date)
        }
        for item in series {
            renderPoints[item.account.id] = UsageHistory.reduce(item.points, project: { positions[$0] ?? viewport.position(at: $0) }, minX: 0, maxX: viewport.contentWidth)
        }
    }
}

/// Saved schedules and calendar-day buckets do not change while the viewport pans.
/// Keep the clock cutoff dynamic so a cached reset disappears at its actual deadline.
struct HorizonFuturePresentation {
    private var schedules: [HorizonEvent] = []
    private var days: [Date: [HorizonEvent]] = [:]
    init() {}
    init(state: PersistedState) {
        schedules = HorizonEvent.events(state: state, now: .distantPast)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = state.settings.zone
        days = Dictionary(grouping: schedules) { calendar.startOfDay(for: $0.date) }
    }
    func events(after now: Date) -> [HorizonEvent] { schedules.filter { $0.date > now } }
    func events(on day: Date, after now: Date) -> [HorizonEvent] {
        (days[day] ?? []).filter { $0.date > now }
    }
    func maximumRows(after now: Date) -> Int {
        days.values.map { $0.count(where: { $0.date > now }) }.max() ?? 0
    }
}

/// Smooth discrete wheel notches without synthesizing additional trackpad inertia.
struct HorizonWheelMotion {
    private(set) var remaining = 0.0
    mutating func enqueue(_ delta: Double) {
        guard delta.isFinite else { return }
        if remaining * delta < 0 { remaining = 0 }
        remaining += delta
    }
    mutating func step(seconds: Double) -> Double {
        guard seconds.isFinite, seconds > 0 else { return 0 }
        if abs(remaining) < 0.1 { let tail = remaining; remaining = 0; return tail }
        let movement = remaining * (1 - exp(-min(seconds, 0.05) / 0.045))
        remaining -= movement
        return movement
    }
    mutating func cancel() { remaining = 0 }
}
