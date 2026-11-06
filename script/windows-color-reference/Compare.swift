import Foundation

enum CompareError: Error { case unexpectedRasterSize(Int); case invalidIndex(UInt8); case unreadableTable }

@main enum Compare {
    static func main() throws {
        guard CommandLine.arguments.count == 4 else {
            print("Usage: compare-colors rgb.bin names.json WindowsColorNames.plist")
            exit(2)
        }
        let raster = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]), options: .mappedIfSafe)
        let names = try JSONDecoder().decode([String].self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2])))
        guard raster.count == 1 << 24 else { throw CompareError.unexpectedRasterSize(raster.count) }
        guard let table = WindowsColorNameTable(data: try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[3]))) else { throw CompareError.unreadableTable }
        var histogram = [String: Int](), mismatches = 0
        var boundaries = [String]()
        try raster.withUnsafeBytes { raw in
            let ids = raw.bindMemory(to: UInt8.self)
            for rgb in 0..<(1 << 24) {
                let id = ids[rgb]
                guard Int(id) < names.count else { throw CompareError.invalidIndex(id) }
                let expected = names[Int(id)], actual = table.name(rgb: UInt32(rgb)) ?? "<missing>"
                if actual != expected {
                    mismatches += 1
                    histogram[actual + " -> " + expected, default: 0] += 1
                    if boundaries.count < 32 { boundaries.append(String(format: "%06X", rgb) + ": " + actual + " -> " + expected) }
                }
            }
        }
        print("Compared \(raster.count) opaque RGB colors across \(names.count) oracle names; \(mismatches) mismatches.")
        for entry in histogram.sorted(by: { $0.value > $1.value }).prefix(20) { print(entry.key, entry.value) }
        for example in boundaries { print(example) }
        if mismatches > 0 { exit(1) }
    }
}
