import Foundation
import CryptoKit

struct PackedHistoryRun: Codable, Sendable {
    var format = 1
    var metadataID: String
    var id: String
    var observedAt: Date
    var providerDataAt: Date?
    var used: [Decimal?]
    var lastObservedAt: Date
    var count: Int
    var pollingMinutes: Int
    var maximumGap: TimeInterval
    var revision: Int64
    static func pack(_ run: HistoryRun) throws -> (record: PackedHistoryRun, metadata: Data) {
        var metadata = run.snapshot
        let used = metadata.windows.map(\.used)
        for index in metadata.windows.indices { metadata.windows[index].used = nil }
        metadata.observedAt = .distantPast; metadata.providerDataAt = nil
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(metadata)
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return (PackedHistoryRun(metadataID: hash, id: run.id, observedAt: run.firstObservedAt, providerDataAt: run.snapshot.providerDataAt,
            used: used, lastObservedAt: run.lastObservedAt, count: run.count, pollingMinutes: run.pollingMinutes,
            maximumGap: run.maximumGap, revision: run.revision), data)
    }
    func unpack(metadata: QuotaSnapshot) throws -> HistoryRun {
        guard format == 1, metadata.windows.count == used.count else { throw StoreError.operation }
        var snapshot = metadata
        snapshot.observedAt = observedAt; snapshot.providerDataAt = providerDataAt
        for index in used.indices { snapshot.windows[index].used = used[index] }
        return HistoryRun(id: id, snapshot: snapshot, lastObservedAt: lastObservedAt, count: count,
                          pollingMinutes: pollingMinutes, maximumGap: maximumGap, revision: revision)
    }
}
