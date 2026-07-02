import MapKit
import XCTest
@testable import BusinessMap

final class MapStateStoreTests: XCTestCase {

    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "MapStateStoreTests")
        defaults.removePersistentDomain(forName: "MapStateStoreTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "MapStateStoreTests")
        super.tearDown()
    }

    func testDefaultRegionIsTokyoStation() {
        let store = MapStateStore(defaults: defaults)
        let region = store.loadRegion()
        XCTAssertEqual(region.center.latitude, 35.681382, accuracy: 0.000001)
        XCTAssertEqual(region.center.longitude, 139.766084, accuracy: 0.000001)
    }

    func testSaveAndLoadRoundTrip() {
        let store = MapStateStore(defaults: defaults)
        let saved = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.702485, longitude: 135.495951),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.03)
        )
        store.save(saved)

        let loaded = MapStateStore(defaults: defaults).loadRegion()
        XCTAssertEqual(loaded.center.latitude, saved.center.latitude, accuracy: 0.000001)
        XCTAssertEqual(loaded.center.longitude, saved.center.longitude, accuracy: 0.000001)
        XCTAssertEqual(loaded.span.latitudeDelta, saved.span.latitudeDelta, accuracy: 0.000001)
        XCTAssertEqual(loaded.span.longitudeDelta, saved.span.longitudeDelta, accuracy: 0.000001)
    }
}
