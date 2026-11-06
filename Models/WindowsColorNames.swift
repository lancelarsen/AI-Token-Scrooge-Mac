import Foundation

/// A lossless encoding of the English names from the Windows app's color picker.
/// Each red/green pair selects a row of (inclusive blue endpoint, name index) runs.
struct WindowsColorNameTable: Sendable {
    private struct Payload: Decodable {
        let version: Int
        let names: [String]
        let runs: Data
    }

    private let names: [String]
    private let runs: [UInt8]
    private let rowStarts: [Int32]

    init?(data: Data) {
        guard let payload = try? PropertyListDecoder().decode(Payload.self, from: data),
              payload.version == 1, (1...256).contains(payload.names.count),
              payload.names.allSatisfy({ !$0.isEmpty }),
              payload.runs.count.isMultiple(of: 2),
              payload.runs.count <= 2 * (1 << 24) else { return nil }
        let runs = Array(payload.runs)
        var rowStarts: [Int32] = []
        rowStarts.reserveCapacity(1 << 16)
        var nextRun = 0
        for _ in 0..<(1 << 16) {
            rowStarts.append(Int32(nextRun))
            var previousEnd = -1
            repeat {
                guard nextRun < runs.count,
                      Int(runs[nextRun]) > previousEnd,
                      Int(runs[nextRun + 1]) < payload.names.count else { return nil }
                previousEnd = Int(runs[nextRun])
                nextRun += 2
            } while previousEnd != 255
        }
        guard nextRun == runs.count else { return nil }
        self.names = payload.names
        self.runs = runs
        self.rowStarts = rowStarts
    }

    func name(rgb: UInt32) -> String? {
        guard rgb <= 0xFFFFFF else { return nil }
        let blue = UInt8(truncatingIfNeeded: rgb)
        var index = Int(rowStarts[Int(rgb >> 8)])
        while blue > runs[index] { index += 2 }
        return names[Int(runs[index + 1])]
    }

    func name(hex: String) -> String? {
        let digits = hex.hasPrefix("#") ? hex.dropFirst() : hex[...]
        guard digits.utf8.count == 6, digits.utf8.allSatisfy({ byte in
            (48...57).contains(byte) || (65...70).contains(byte) || (97...102).contains(byte)
        }), let rgb = UInt32(digits, radix: 16) else { return nil }
        return name(rgb: rgb)
    }
}
