import CoreLocation
import Foundation

/// 連絡先の1住所ぶんを表す。複数の住所を持つ連絡先は住所ごとに1件になる
/// (Android版が RawContact × 住所で行を展開しているのと同じ考え方)。
struct Contact: Identifiable, Hashable, Sendable {
    /// `contactId` と住所インデックスから作る一意なID
    let id: String
    /// CNContact.identifier。連絡先詳細画面を開くときに使う
    let contactId: String
    let displayName: String
    let phoneticName: String?
    let organizationName: String?
    /// 1行に整形済みの住所。住所を持たない連絡先では nil
    let postalAddress: String?
    let thumbnailData: Data?
    var latitude: Double?
    var longitude: Double?

    init(
        id: String,
        contactId: String,
        displayName: String,
        phoneticName: String? = nil,
        organizationName: String? = nil,
        postalAddress: String? = nil,
        thumbnailData: Data? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.contactId = contactId
        self.displayName = displayName
        self.phoneticName = phoneticName
        self.organizationName = organizationName
        self.postalAddress = postalAddress
        self.thumbnailData = thumbnailData
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
