import XCTest
@testable import AITokenScrooge

final class WindowsColorNamesTests: XCTestCase {
    func testGraysAndLightnessVariants() {
        let samples = [
            ("000000", "Black"), ("454545", "Dark gray"),
            ("888888", "Gray"), ("CDCDCD", "Light gray"), ("FFFFFF", "White"),
            ("7C0000", "Dark red"), ("FF0000", "Red"), ("FF6969", "Rose")
        ]
        for (hex, expected) in samples {
            XCTAssertEqual(WindowsColorNames.name(hex: hex), expected, hex)
        }
    }

    func testChromaticSamplesAcrossWinUISaturationBands() {
        // Colors sampled from the Windows release used by the reference generator.
        let samples = [
            ("957F60", "Brown"), ("4A78AB", "Blue-gray"), ("3AB53D", "Green"),
            ("24D577", "Bright green"), ("F5AE02", "Gold"), ("045FF5", "Blue"),
            ("D587A5", "Pink"), ("0094B9", "Dark teal"), ("00ACD7", "Aqua")
        ]
        for (hex, expected) in samples {
            XCTAssertEqual(WindowsColorNames.name(hex: hex), expected, hex)
        }
        XCTAssertEqual(WindowsColorNames.name(hex: "#4a78ab"), "Blue-gray")
    }

    func testMalformedAndIncompleteHexHaveNoName() {
        for hex in ["", "#F", "#F801", "12345G", " 00000", "+FF000", "FFFFFFFF"] {
            XCTAssertNil(WindowsColorNames.name(hex: hex), hex)
        }
    }
}
