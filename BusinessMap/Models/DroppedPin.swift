import CoreLocation
import Foundation

/// 地図の長押しで置かれるピン(Android版の longPressMarker 相当)。
struct DroppedPin: Identifiable, Hashable, Sendable {
    let id: UUID
    let latitude: Double
    let longitude: Double

    init(coordinate: CLLocationCoordinate2D) {
        self.id = UUID()
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
