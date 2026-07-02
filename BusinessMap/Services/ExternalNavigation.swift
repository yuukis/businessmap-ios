import MapKit

/// Apple マップでの経路案内を開く(Android版の Google Maps 経路/ナビ起動の置き換え)。
/// iOS では経路表示とナビ開始が Apple マップ側で一続きになっているため、
/// Android版の「経路」「ナビ」2アクションは1つに統合している。
@MainActor
enum ExternalNavigation {
    static func openDirections(to coordinate: CLLocationCoordinate2D, name: String?) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
        ])
    }
}
