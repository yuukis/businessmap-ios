import Foundation
import MapKit

/// 最後に表示していた地図領域を UserDefaults に保存・復元する
/// (Android版 MapStatePreferences 相当。tilt/bearing は SwiftUI Map では扱わない)。
struct MapStateStore {

    private enum Key {
        static let latitude = "map.center.latitude"
        static let longitude = "map.center.longitude"
        static let latitudeDelta = "map.span.latitudeDelta"
        static let longitudeDelta = "map.span.longitudeDelta"
    }

    /// 既定値: 東京駅周辺(Android版と同じフォールバック地点)
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.681382, longitude: 139.766084),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadRegion() -> MKCoordinateRegion {
        guard
            let latitude = defaults.object(forKey: Key.latitude) as? Double,
            let longitude = defaults.object(forKey: Key.longitude) as? Double,
            let latitudeDelta = defaults.object(forKey: Key.latitudeDelta) as? Double,
            let longitudeDelta = defaults.object(forKey: Key.longitudeDelta) as? Double
        else {
            return Self.defaultRegion
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }

    func save(_ region: MKCoordinateRegion) {
        defaults.set(region.center.latitude, forKey: Key.latitude)
        defaults.set(region.center.longitude, forKey: Key.longitude)
        defaults.set(region.span.latitudeDelta, forKey: Key.latitudeDelta)
        defaults.set(region.span.longitudeDelta, forKey: Key.longitudeDelta)
    }
}
