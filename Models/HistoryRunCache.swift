import Foundation

struct HistoryRunCache: Sendable {
    private(set) var revision: Int64?
    private(set) var runs: [HistoryRun] = []
    private(set) var rangeStart: Date?
    func covers(since: Date) -> Bool { rangeStart.map { since >= $0 } ?? false }
    mutating func merge(_ changes: [HistoryRun], revision: Int64, since: Date) {
        var byID = Dictionary(uniqueKeysWithValues: runs.map { ($0.id, $0) })
        for run in changes { byID[run.id] = run }
        let ordered = byID.values.sorted { $0.firstObservedAt < $1.firstObservedAt }
        let anchor = ordered.last { $0.lastObservedAt < since }?.id
        runs = ordered.filter { $0.lastObservedAt >= since || $0.id == anchor }
        self.revision = revision
        rangeStart = since
    }
}
