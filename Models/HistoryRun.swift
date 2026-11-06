import Foundation

struct HistoryRun: Codable, Identifiable, Equatable, Sendable {
    var id: String = UUID().uuidString
    var snapshot: QuotaSnapshot
    var lastObservedAt: Date
    var count = 1
    var pollingMinutes: Int
    var maximumGap: TimeInterval = 0
    var revision: Int64 = 0
    var firstObservedAt: Date { snapshot.observedAt }
    func canExtend(with next: QuotaSnapshot, polling: Int) -> Bool {
        let gap = next.observedAt.timeIntervalSince(lastObservedAt)
        guard gap >= 1, gap <= max(900, Double(polling * 180)), polling == pollingMinutes else { return false }
        let boundaries = snapshot.windows.compactMap(\.resetsAt) + (snapshot.reserve?.credits?.compactMap(\.expiresAt) ?? [])
        guard !boundaries.contains(where: { $0 > lastObservedAt && $0 <= next.observedAt }) else { return false }
        var old = snapshot; var new = next
        old.observedAt = .distantPast; new.observedAt = .distantPast
        old.providerDataAt = nil; new.providerDataAt = nil
        return old == new
    }
}
