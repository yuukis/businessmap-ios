import CoreLocation

/// 現在地表示のための位置情報権限を要求する最小限のラッパー。
/// 位置の取得自体は SwiftUI Map の UserAnnotation が行う。
final class LocationAuthorization {
    private let manager = CLLocationManager()

    func requestWhenInUseIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
}
