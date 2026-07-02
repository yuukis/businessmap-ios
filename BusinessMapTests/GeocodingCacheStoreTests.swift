import XCTest
@testable import BusinessMap

final class GeocodingCacheStoreTests: XCTestCase {

    private var url: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        url = FileManager.default.temporaryDirectory
            .appending(path: "geocoding-test-\(UUID().uuidString).sqlite")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: url)
        try super.tearDownWithError()
    }

    func testMissForUnknownAddress() throws {
        let store = try GeocodingCacheStore(url: url)
        XCTAssertEqual(store.lookup("東京都千代田区丸の内1-9-1"), .miss)
    }

    func testFoundAfterSave() throws {
        let store = try GeocodingCacheStore(url: url)
        store.save("東京都千代田区丸の内1-9-1", latitude: 35.681382, longitude: 139.766084)
        XCTAssertEqual(
            store.lookup("東京都千代田区丸の内1-9-1"),
            .found(latitude: 35.681382, longitude: 139.766084)
        )
    }

    func testNotFoundResultIsCachedAsUnresolved() throws {
        let store = try GeocodingCacheStore(url: url)
        store.save("存在しない住所", latitude: nil, longitude: nil)
        XCTAssertEqual(store.lookup("存在しない住所"), .unresolved)
    }

    func testStaleFailureBecomesMissAgain() throws {
        let store = try GeocodingCacheStore(url: url, failureRetryInterval: 0)
        store.save("存在しない住所", latitude: nil, longitude: nil)
        XCTAssertEqual(store.lookup("存在しない住所"), .miss)
    }

    func testSuccessOverwritesFailure() throws {
        let store = try GeocodingCacheStore(url: url)
        store.save("東京都千代田区丸の内1-9-1", latitude: nil, longitude: nil)
        store.save("東京都千代田区丸の内1-9-1", latitude: 35.681382, longitude: 139.766084)
        XCTAssertEqual(
            store.lookup("東京都千代田区丸の内1-9-1"),
            .found(latitude: 35.681382, longitude: 139.766084)
        )
    }

    func testPersistsAcrossReopen() throws {
        var store: GeocodingCacheStore? = try GeocodingCacheStore(url: url)
        store?.save("東京都千代田区丸の内1-9-1", latitude: 35.681382, longitude: 139.766084)
        store = nil

        let reopened = try GeocodingCacheStore(url: url)
        XCTAssertEqual(
            reopened.lookup("東京都千代田区丸の内1-9-1"),
            .found(latitude: 35.681382, longitude: 139.766084)
        )
    }
}
