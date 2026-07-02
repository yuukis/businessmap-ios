import Contacts
import CoreLocation
import Foundation

/// CLGeocoder による住所⇔座標の変換。
/// CLGeocoder は同時に1リクエストしか処理できないため、actor で直列化する。
actor GeocodingService {
    private let geocoder = CLGeocoder()

    /// 住所から座標を求める。該当なしの場合は nil を返し、
    /// ネットワークエラー等は throw する(呼び出し側で中断・再試行を判断する)。
    func coordinate(for address: String) async throws -> CLLocationCoordinate2D? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            return placemarks.first?.location?.coordinate
        } catch let error as CLError where error.code == .geocodeFoundNoResult {
            return nil
        }
    }

    struct ReverseGeocodedAddress: @unchecked Sendable {
        /// 1行に整形した表示用の住所
        let formatted: String
        /// 連絡先登録に使う構造化住所
        let postalAddress: CNPostalAddress?
    }

    /// 座標から住所を求める(長押しピン用の逆ジオコーディング)。
    func address(for coordinate: CLLocationCoordinate2D) async throws -> ReverseGeocodedAddress? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try await geocoder.reverseGeocodeLocation(location).first else {
            return nil
        }
        let formatted: String
        if let postal = placemark.postalAddress {
            formatted = CNPostalAddressFormatter
                .string(from: postal, style: .mailingAddress)
                .replacingOccurrences(of: "\n", with: " ")
        } else {
            formatted = placemark.name ?? ""
        }
        return ReverseGeocodedAddress(formatted: formatted, postalAddress: placemark.postalAddress)
    }
}
