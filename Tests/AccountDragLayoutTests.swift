import XCTest
@testable import AITokenScrooge

final class AccountDragLayoutTests: XCTestCase {
    @MainActor
    func testFinalSlotPersistsAndStaleOrInvalidDragsDoNotOverwriteOrder() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let database = try LocalStore(url: directory.appendingPathComponent("order.db"))
        var initial = PersistedState()
        initial.accounts = ["a", "b", "c"].map {
            ProviderAccount(id: $0, provider: .codex, nickname: $0, subject: $0, scope: "scope")
        }
        initial.settings.accountSort = .custom
        try await database.save(initial)
        let store = AppStore(database: database)
        await store.load()
        await store.moveAccount("a", to: 2, expectedOrder: ["a", "b", "c"])
        XCTAssertEqual(store.accounts.map(\.id), ["b", "c", "a"])
        let saved = try await database.load()
        XCTAssertEqual(saved.settings.accountOrder, ["b", "c", "a"])
        await store.moveAccount("b", to: 2, expectedOrder: ["a", "b", "c"])
        await store.moveAccount("missing", to: 1, expectedOrder: ["b", "c", "a"])
        await store.moveAccount("a", to: 3, expectedOrder: ["b", "c", "a"])
        XCTAssertEqual(store.accounts.map(\.id), ["b", "c", "a"])
        await store.moveAccount("a", to: 0, expectedOrder: ["b", "c", "a"])
        XCTAssertEqual(store.accounts.map(\.id), ["a", "b", "c"])
        store.edit { $0.settings.accountSort = .mostRemaining }
        await store.waitForPendingMutations()
        await store.moveAccount("a", to: 2, expectedOrder: ["a", "b", "c"])
        XCTAssertEqual(store.state.settings.accountOrder, ["a", "b", "c"])
    }

    func testSmallMovementKeepsOriginalGap() throws {
        var layout = try XCTUnwrap(AccountDragLayout(heights: [200, 100, 200], sourceIndex: 0, spacing: 20))
        XCTAssertFalse(layout.move(centerY: 110))
        XCTAssertEqual(layout.slot, 0)
        XCTAssertEqual(layout.tops, [0, 220, 340])
    }

    func testDifferentHeightCardsDoNotFlickerAtCrossedBoundary() throws {
        var layout = try XCTUnwrap(AccountDragLayout(heights: [200, 100, 200], sourceIndex: 0, spacing: 20))
        XCTAssertTrue(layout.move(centerY: 280))
        XCTAssertEqual(layout.slot, 1)
        XCTAssertEqual(layout.tops, [120, 0, 340])
        XCTAssertFalse(layout.move(centerY: 275))
        XCTAssertTrue(layout.move(centerY: 40))
        XCTAssertEqual(layout.tops, layout.originalTops)
    }

    func testCrossesSeveralCardsAndReturns() throws {
        var layout = try XCTUnwrap(AccountDragLayout(heights: [100, 200, 100, 100], sourceIndex: 2, spacing: 20))
        layout.move(centerY: -100)
        XCTAssertEqual(layout.slot, 0)
        layout.move(centerY: 10000)
        XCTAssertEqual(layout.slot, 3)
        XCTAssertEqual(layout.tops, [0, 120, 460, 340])
        layout.move(centerY: 350)
        XCTAssertEqual(layout.slot, 2)
        XCTAssertEqual(layout.tops, layout.originalTops)
    }

    func testEdgeScrollingStopsOutsideAndScalesNearEdges() {
        for y in [90.0, 300, 510] {
            XCTAssertEqual(AccountDragLayout.scrollStep(pointerY: y, top: 100, bottom: 500), 0)
        }
        XCTAssertEqual(AccountDragLayout.scrollStep(pointerY: 100, top: 100, bottom: 500), -10)
        XCTAssertEqual(AccountDragLayout.scrollStep(pointerY: 500, top: 100, bottom: 500), 10)
        XCTAssertEqual(AccountDragLayout.scrollStep(pointerY: 480, top: 100, bottom: 500), 10 * (1 - 20.0 / 56), accuracy: 0.0001)
        XCTAssertEqual(AccountDragLayout.scrollStep(pointerY: 10, top: 0, bottom: 60), -5)
        XCTAssertEqual(AccountDragLayout.scrollStep(pointerY: 100, top: 100, bottom: 100), 0)
    }

    func testInvalidGeometryAndSingleAccountAreSafe() throws {
        XCTAssertNil(AccountDragLayout(heights: [], sourceIndex: 0, spacing: 20))
        XCTAssertNil(AccountDragLayout(heights: [100], sourceIndex: 1, spacing: 20))
        XCTAssertNil(AccountDragLayout(heights: [.nan], sourceIndex: 0, spacing: 20))
        var layout = try XCTUnwrap(AccountDragLayout(heights: [100], sourceIndex: 0, spacing: 20))
        XCTAssertFalse(layout.move(centerY: 10000))
        XCTAssertFalse(layout.move(centerY: .nan))
        XCTAssertEqual(layout.tops, [0])
        XCTAssertEqual(AccountDragLayout.scrollStep(pointerY: .nan, top: 0, bottom: 100), 0)
    }
}
