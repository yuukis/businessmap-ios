import Contacts
import CoreLocation
import Foundation
import Observation

struct GeocodingProgress: Equatable {
    let done: Int
    let total: Int
}

struct AlertMessage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}

/// 連絡先・グループ・ジオコーディング進捗を管理するアプリの中心的な状態。
/// Android版の MainActivityViewModel に相当する。
/// 検索や地図上の選択は各 View のローカル状態として持つ。
@MainActor
@Observable
final class ContactsModel {

    enum ContactsAccess {
        case undetermined
        case granted
        case denied
    }

    private(set) var access: ContactsAccess = .undetermined
    private(set) var groups: [ContactGroup] = [.allContacts]
    var selectedGroupID: ContactGroup.GroupID = .all
    private(set) var contacts: [Contact] = []
    /// 選択中グループの連絡先 identifier 集合。nil は「すべての連絡先」
    private(set) var groupMemberIDs: Set<String>?
    private(set) var geocodingProgress: GeocodingProgress?
    private(set) var isLoading = false
    var errorMessage: AlertMessage?

    private let repository: ContactRepository
    private let geocoding: GeocodingService
    private let cache: GeocodingCacheStore?
    private var hasLoaded = false

    init(
        repository: ContactRepository = ContactRepository(),
        geocoding: GeocodingService = GeocodingService(),
        cache: GeocodingCacheStore? = try? GeocodingCacheStore(url: GeocodingCacheStore.defaultURL())
    ) {
        self.repository = repository
        self.geocoding = geocoding
        self.cache = cache
    }

    /// 選択中グループで絞り込んだ連絡先(住所なしも含む。一覧表示用)
    var visibleContacts: [Contact] {
        guard let members = groupMemberIDs else { return contacts }
        return contacts.filter { members.contains($0.contactId) }
    }

    /// 地図に表示するピン(座標が解決できた連絡先のみ)
    var places: [MapPlace] {
        MapPlace.places(from: visibleContacts)
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await load()
    }

    func reload() async {
        await load()
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        guard await repository.requestAccess() else {
            access = .denied
            contacts = []
            return
        }
        access = .granted

        let repository = self.repository
        do {
            let loadedGroups = try await Task.detached { try repository.fetchGroups() }.value
            groups = [.allContacts] + loadedGroups
            if !groups.contains(where: { $0.id == selectedGroupID }) {
                selectedGroupID = .all
            }

            var loaded = try await Task.detached { try repository.fetchContacts() }.value

            // キャッシュ済みの座標を反映し、未解決の住所を集める
            var pendingAddresses: [String] = []
            var seen = Set<String>()
            for index in loaded.indices {
                guard let address = loaded[index].postalAddress else { continue }
                switch cache?.lookup(address) ?? .miss {
                case .found(let latitude, let longitude):
                    loaded[index].latitude = latitude
                    loaded[index].longitude = longitude
                case .unresolved:
                    break
                case .miss:
                    if seen.insert(address).inserted {
                        pendingAddresses.append(address)
                    }
                }
            }
            contacts = loaded
            await updateGroupMembers()
            await geocode(pendingAddresses)
        } catch {
            errorMessage = AlertMessage(
                title: String(localized: "error.contacts.title"),
                message: String(localized: "error.contacts.message")
            )
        }
    }

    func updateGroupMembers() async {
        switch selectedGroupID {
        case .all:
            groupMemberIDs = nil
        case .group(let identifier):
            let repository = self.repository
            groupMemberIDs = (try? await Task.detached {
                try repository.fetchMemberIdentifiers(groupIdentifier: identifier)
            }.value) ?? []
        }
    }

    /// 長押しピン用の逆ジオコーディング
    func reverseGeocodedAddress(
        for coordinate: CLLocationCoordinate2D
    ) async -> GeocodingService.ReverseGeocodedAddress? {
        try? await geocoding.address(for: coordinate)
    }

    /// 未解決の住所を1件ずつ座標に変換する。
    /// ネットワークエラー時は Android版と同じく中断し、次回読み込みで再試行する。
    private func geocode(_ addresses: [String]) async {
        guard !addresses.isEmpty else { return }
        geocodingProgress = GeocodingProgress(done: 0, total: addresses.count)
        defer { geocodingProgress = nil }

        for (index, address) in addresses.enumerated() {
            do {
                let coordinate = try await geocodeWithRetry(address)
                cache?.save(address, latitude: coordinate?.latitude, longitude: coordinate?.longitude)
                if let coordinate {
                    applyCoordinate(coordinate, to: address)
                }
            } catch {
                errorMessage = AlertMessage(
                    title: String(localized: "error.geocoding.title"),
                    message: String(localized: "error.geocoding.message")
                )
                return
            }
            geocodingProgress = GeocodingProgress(done: index + 1, total: addresses.count)
            // CLGeocoder のレート制限対策として問い合わせ間隔を空ける
            try? await Task.sleep(for: .milliseconds(600))
        }
    }

    /// CLGeocoder はリクエストが集中すると、端末がオンラインでも
    /// CLError.network を返してスロットリングする。少し待って再試行し、
    /// それでも失敗する場合だけエラーとして扱う。
    private func geocodeWithRetry(_ address: String) async throws -> CLLocationCoordinate2D? {
        let retryDelays: [Duration] = [.seconds(3), .seconds(10)]
        for delay in retryDelays {
            do {
                return try await geocoding.coordinate(for: address)
            } catch {
                try? await Task.sleep(for: delay)
            }
        }
        return try await geocoding.coordinate(for: address)
    }

    private func applyCoordinate(_ coordinate: CLLocationCoordinate2D, to address: String) {
        for index in contacts.indices where contacts[index].postalAddress == address {
            contacts[index].latitude = coordinate.latitude
            contacts[index].longitude = coordinate.longitude
        }
    }
}
