import Foundation

enum WindowsColorNames {
    private static let table: WindowsColorNameTable? = {
        guard let url = Bundle.main.url(forResource: "WindowsColorNames", withExtension: "plist"),
              let data = try? Data(contentsOf: url) else { return nil }
        return WindowsColorNameTable(data: data)
    }()

    static func name(hex: String) -> String? {
        table?.name(hex: hex)
    }
}
