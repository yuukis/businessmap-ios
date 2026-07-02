import CoreLocation
import Foundation

/// 地図上の1本のピン。同一座標に複数の連絡先がある場合は1つのピンにまとめる
/// (Android版の latlngContactsHashMap 相当)。
struct MapPlace: Identifiable, Hashable, Sendable {
    let id: String
    let latitude: Double
    let longitude: Double
    let contacts: [Contact]

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var title: String {
        contacts.first?.displayName ?? ""
    }

    static func places(from contacts: [Contact]) -> [MapPlace] {
        var grouped: [String: [Contact]] = [:]
        for contact in contacts {
            guard let lat = contact.latitude, let lng = contact.longitude else { continue }
            let key = String(format: "%.6f,%.6f", lat, lng)
            grouped[key, default: []].append(contact)
        }
        return grouped
            .map { key, members in
                MapPlace(
                    id: key,
                    latitude: members[0].latitude ?? 0,
                    longitude: members[0].longitude ?? 0,
                    contacts: members
                )
            }
            .sorted { $0.id < $1.id }
    }
}
