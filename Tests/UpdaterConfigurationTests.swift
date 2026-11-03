import XCTest
@testable import AITokenScrooge

final class UpdaterConfigurationTests: XCTestCase {
    func testUpdateChannelRequiresSignedFeedAndPreExtractionVerification() {
        let bundle = Bundle.main
        XCTAssertEqual(bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String,
                       "https://github.com/lancelarsen/AI-Token-Scrooge-Mac/releases/download/mac-updates/appcast.xml")
        XCTAssertEqual(Data(base64Encoded: bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? "")?.count, 32)
        for key in ["SURequireSignedFeed", "SUVerifyUpdateBeforeExtraction"] {
            XCTAssertEqual((bundle.object(forInfoDictionaryKey: key) as? NSNumber)?.boolValue, true)
        }
        XCTAssertEqual((bundle.object(forInfoDictionaryKey: "SUAutomaticallyUpdate") as? NSNumber)?.boolValue, false)
        XCTAssertEqual((bundle.object(forInfoDictionaryKey: "SUSendProfileInfo") as? NSNumber)?.boolValue, false)
    }
}
