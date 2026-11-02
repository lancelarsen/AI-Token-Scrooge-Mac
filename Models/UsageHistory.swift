import Foundation

struct HistoryPoint: Equatable, Sendable {
    var at: Date
    var remaining: Decimal
    var windowID: String
    var startsSegment: Bool
    var estimated: Bool
    var replenishedFrom: Decimal?
    var previousObservedAt: Date? = nil
}
struct UsageHistorySeries: Sendable {
    var account: ProviderAccount
    var points: [HistoryPoint]
    var status: String?
}
enum UsageHistory {
    static func estimatedPoint(points: [HistoryPoint], x: Double, y: Double, viewport: HorizonViewport) -> HistoryPoint? {
        guard let index = points.firstIndex(where: { viewport.position(at: $0.at) >= x }), index > 0 else { return nil }
        let after = points[index], before = points[index - 1]
        guard after.estimated, !after.startsSegment else { return nil }
        let startX = viewport.position(at: before.at), endX = viewport.position(at: after.at)
        guard endX > startX, x >= startX else { return nil }
        let fraction = (x - startX) / (endX - startX)
        let remaining = before.remaining + (after.remaining - before.remaining) * Decimal(fraction)
        guard abs(95 + NSDecimalNumber(decimal: remaining).doubleValue * 2 - y) <= 24 else { return nil }
        return HistoryPoint(at: before.at.addingTimeInterval(after.at.timeIntervalSince(before.at) * fraction),
            remaining: remaining, windowID: after.windowID, startsSegment: false, estimated: true)
    }
    static func selectWindow(provider: Provider, windows: [QuotaWindow]) -> (window: QuotaWindow?, ambiguous: Bool) {
        let eligible = windows.filter { window in
            switch provider {
            case .codex: return window.durationMinutes == 10080
            case .claude: return window.durationMinutes == 10080 || (window.id == "weekly" && window.durationMinutes == nil)
            case .copilot: return window.id == "copilot/monthly"
            }
        }
        if eligible.count < 2 { return (eligible.first, false) }
        let canonical = eligible.filter { provider == .codex ? $0.id.hasPrefix("codex/") : provider == .claude && $0.id == "weekly" }
        return canonical.count == 1 ? (canonical[0], false) : (nil, true)
    }
    static func build(account: ProviderAccount, runs: [HistoryRun], from: Date, through: Date) -> UsageHistorySeries {
        var points: [HistoryPoint] = []
        var previousWindow: QuotaWindow?
        var previousSnapshot: QuotaSnapshot?
        var missed = false
        var status: String?
        let period = account.provider == .copilot ? "Monthly" : "Weekly"
        let ordered = runs.filter { $0.snapshot.accountID == account.id && $0.firstObservedAt <= through }.sorted { $0.firstObservedAt < $1.firstObservedAt }
        let anchor = ordered.last { $0.lastObservedAt < from }?.id
        for run in ordered where run.lastObservedAt >= from || run.id == anchor {
            let snapshot = run.snapshot
            guard snapshot.belongs(to: account) else { previousWindow = nil; previousSnapshot = nil; missed = true; status = "Waiting for Fresh Usage"; continue }
            guard snapshot.health == .healthy || snapshot.health == .demo else { missed = true; status = "Waiting for Fresh Usage"; continue }
            let selected = selectWindow(provider: account.provider, windows: snapshot.windows)
            guard let window = selected.window else {
                missed = true; status = selected.ambiguous ? "Multiple \(period) Limits Reported" : "No \(period) Limit Reported"; continue
            }
            guard let remaining = window.remainingPercent else { missed = true; status = "Remaining Capacity Unavailable"; continue }
            let maxGap = max(900, Double(run.pollingMinutes * 180))
            if run.lastObservedAt < from && from.timeIntervalSince(run.lastObservedAt) > maxGap { continue }
            let starts = points.isEmpty || previousWindow == nil || previousSnapshot == nil || window.id != previousWindow?.id
                || window.unit != previousWindow?.unit || window.limit != previousWindow?.limit
                || window.allowanceSource != previousWindow?.allowanceSource || snapshot.planType != previousSnapshot?.planType
                || !(previousSnapshot.map { account.scopeEquals($0.scope) } ?? false)
            let estimated = !starts && (missed || snapshot.observedAt.timeIntervalSince(points.last!.at) > maxGap)
            let replenished = !starts && !estimated && remaining > points.last!.remaining ? points.last!.remaining : nil
            points.append(HistoryPoint(at: snapshot.observedAt, remaining: remaining, windowID: window.id, startsSegment: starts, estimated: estimated, replenishedFrom: replenished, previousObservedAt: starts ? nil : points.last?.at))
            // Compacted runs provide exact observed endpoints and a measured continuity bound.
            if run.lastObservedAt > snapshot.observedAt, run.lastObservedAt <= through {
                points.append(HistoryPoint(at: run.lastObservedAt, remaining: remaining, windowID: window.id, startsSegment: false, estimated: run.maximumGap > maxGap, replenishedFrom: nil))
            }
            previousWindow = window; previousSnapshot = snapshot; missed = false; status = nil
        }
        if points.isEmpty { status = status ?? "No Recorded History Yet" }
        else if through.timeIntervalSince(points.last!.at) > max(900, Double(account.effectivePollingMinutes * 180)) { status = status ?? "Waiting for Fresh Usage" }
        return UsageHistorySeries(account: account, points: points, status: status)
    }
    static func events(account: ProviderAccount, runs: [HistoryRun], from: Date, through: Date) -> [HorizonEvent] {
        var pending: [String: HorizonEvent] = [:]
        var expirations: [String: HorizonEvent] = [:]
        var events: [String: HorizonEvent] = [:]
        for run in runs.sorted(by: { $0.firstObservedAt < $1.firstObservedAt }) {
            let snapshot = run.snapshot
            guard snapshot.observedAt <= through, snapshot.belongs(to: account), snapshot.health == .healthy || snapshot.health == .demo else { continue }
            if let window = selectWindow(provider: account.provider, windows: snapshot.windows).window, let at = window.resetsAt {
                if let prior = pending[window.id], prior.date != at, snapshot.observedAt >= prior.date { events[prior.id] = prior }
                pending[window.id] = HorizonEvent(id: "history/\(account.id)/refresh/\(window.id)/\(at.timeIntervalSince1970)", account: account, date: at,
                    expiration: false, title: "Scheduled \(account.provider == .copilot ? "Monthly" : "Weekly") Quota Refresh", plan: snapshot.planType, reportedAt: snapshot.observedAt)
            }
            for credit in snapshot.reserve?.credits ?? [] {
                if credit.status == "available", let expiry = credit.expiresAt {
                    expirations[credit.id] = HorizonEvent(id: "history/\(account.id)/credit/\(credit.id)", account: account, date: expiry,
                        expiration: true, title: "Last Reported Earned Reset Expiration", plan: snapshot.planType, reportedAt: snapshot.observedAt)
                } else if ["used", "redeemed"].contains(credit.status), let known = expirations[credit.id], snapshot.observedAt < known.date {
                    expirations.removeValue(forKey: credit.id)
                }
            }
        }
        for event in Array(pending.values) + Array(expirations.values) { events[event.id] = event }
        return events.values.filter { $0.date >= from && $0.date <= through }.sorted { $0.date == $1.date ? $0.id < $1.id : $0.date < $1.date }
    }
    /// Drawing-only reduction; callers retain originals for hover details.
    static func reduce(_ points: [HistoryPoint], project: (Date) -> Double, minX: Double, maxX: Double) -> [HistoryPoint] {
        guard !points.isEmpty, minX <= maxX else { return [] }
        func bound(_ x: Double, inclusive: Bool) -> Int {
            var low = 0, high = points.count
            while low < high {
                let mid = (low + high) / 2, position = project(points[mid].at)
                if position < x || (!inclusive && position == x) { low = mid + 1 } else { high = mid }
            }
            return low
        }
        let first = max(0, bound(minX, inclusive: true) - 1)
        let last = min(points.count - 1, bound(maxX, inclusive: false))
        guard first <= last else { return [] }
        var retained = Set<Int>(), bucket = Double.nan
        var start = first, end = first, minimum = first, maximum = first
        func keep() { retained.formUnion([start, end, minimum, maximum]) }
        for index in first...last {
            let x = floor(project(points[index].at))
            if x != bucket {
                if !bucket.isNaN { keep() }
                bucket = x; start = index; minimum = index; maximum = index
            }
            end = index
            if points[index].remaining < points[minimum].remaining { minimum = index }
            if points[index].remaining > points[maximum].remaining { maximum = index }
            if points[index].startsSegment || points[index].estimated || points[index].replenishedFrom != nil || (index > first && points[index - 1].estimated) {
                retained.insert(index); if index > first { retained.insert(index - 1) }
            }
        }
        keep()
        return retained.sorted().map { points[$0] }
    }
}
