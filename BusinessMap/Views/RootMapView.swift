import MapKit
import SwiftUI

/// 表示するシートの種類。同時に1枚しか出せないため1つの enum で管理する。
enum MapSheet: Identifiable {
    case contactList
    case place(MapPlace)
    case contact(Contact)
    case location(DroppedPin)

    var id: String {
        switch self {
        case .contactList: "contactList"
        case .place(let place): "place-\(place.id)"
        case .contact(let contact): "contact-\(contact.id)"
        case .location(let pin): "location-\(pin.id)"
        }
    }
}

/// 地図を全面に表示するメイン画面。
/// コンパクト幅では一覧・詳細をシートで、レギュラー幅 (iPad など) では
/// 同じコンテンツを左下のフローティングカードで表示する。
struct RootMapView: View {
    @Environment(ContactsModel.self) private var model
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var position: MapCameraPosition
    @State private var activeSheet: MapSheet?
    @State private var droppedPin: DroppedPin?
    @State private var locationAuthorization = LocationAuthorization()

    private let mapStateStore: MapStateStore

    init(mapStateStore: MapStateStore = MapStateStore()) {
        self.mapStateStore = mapStateStore
        _position = State(initialValue: .region(mapStateStore.loadRegion()))
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                UserAnnotation()
                ForEach(model.places) { place in
                    Annotation(place.title, coordinate: place.coordinate, anchor: .bottom) {
                        PlacePinView(count: place.contacts.count)
                            .onTapGesture { activeSheet = .place(place) }
                    }
                }
                if let pin = droppedPin {
                    Annotation(
                        String(localized: "location.title"),
                        coordinate: pin.coordinate,
                        anchor: .bottom
                    ) {
                        DroppedPinView()
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                mapStateStore.save(context.region)
            }
            .simultaneousGesture(dropPinGesture(proxy: proxy))
        }
        .overlay(alignment: .topLeading) {
            groupMenuCapsule
                .padding(.leading)
                .padding(.top, 8)
        }
        .overlay(alignment: .top) {
            statusIndicator
                .padding(.top, 64)
        }
        .overlay(alignment: .bottomLeading) {
            // レギュラー幅ではシートの代わりに左下のフローティングカードで表示する
            if isWidePresentation, let sheet = activeSheet {
                floatingCard(for: sheet)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !isWidePresentation {
                searchBar
            } else if activeSheet == nil {
                // iPhone と同じ検索チップを、地図を隠さない幅で左寄せに置く
                searchBar
                    .frame(maxWidth: 420)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .overlay {
            accessDeniedOverlay
        }
        .sheet(item: sheetBinding, onDismiss: {
            // シートをユーザーが閉じたときだけ長押しピンを消す。
            // サイズクラス切替による自動 dismiss では選択状態が残るため消さない。
            if activeSheet == nil {
                droppedPin = nil
            }
        }) { sheet in
            sheetContent(for: sheet)
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
        .alert(
            model.errorMessage?.title ?? "",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )
        ) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(model.errorMessage?.message ?? "")
        }
        .task {
            locationAuthorization.requestWhenInUseIfNeeded()
            await model.loadIfNeeded()
        }
        .onChange(of: model.selectedGroupID) {
            Task { await model.updateGroupMembers() }
        }
    }

    // MARK: - Presentation

    /// レギュラー幅ではシートの代わりにフローティングカードで表示する
    private var isWidePresentation: Bool {
        horizontalSizeClass == .regular
    }

    /// コンパクト幅のときだけシートを出す。レギュラー幅では常に nil を返し、
    /// 選択状態 (`activeSheet`) はフローティングカード側で描画する。
    private var sheetBinding: Binding<MapSheet?> {
        isWidePresentation ? .constant(nil) : $activeSheet
    }

    // MARK: - Subviews

    @ViewBuilder
    private func floatingCard(for sheet: MapSheet) -> some View {
        // 一覧はナビゲーションバーに「閉じる」を持つため ✕ を重ねない
        let hasOwnCloseButton: Bool = switch sheet {
        case .contactList: true
        case .place, .contact, .location: false
        }
        FloatingCardView(
            height: cardHeight(for: sheet),
            showsCloseButton: !hasOwnCloseButton,
            onClose: closeSelection
        ) {
            sheetContent(for: sheet)
        }
    }

    /// コンテンツ量に応じたカードの最大高さ。
    /// 詳細系は必要最小限にして地図の視認性を優先する。
    private func cardHeight(for sheet: MapSheet) -> CGFloat {
        switch sheet {
        case .contactList: 480
        case .place(let place): place.contacts.count == 1 ? 360 : 480
        case .contact: 360
        case .location: 320
        }
    }

    private var groupMenuCapsule: some View {
        GroupMenuView { name in
            Label(name, systemImage: "person.2")
                .font(.subheadline)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if let progress = model.geocodingProgress {
            HStack(spacing: 8) {
                ProgressView()
                Text(String(
                    format: String(localized: "geocoding.progress"),
                    progress.done, progress.total
                ))
                .font(.footnote)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
        } else if model.isLoading {
            HStack(spacing: 8) {
                ProgressView()
                Text("loading.contacts")
                    .font(.footnote)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
        }
    }

    private var searchBar: some View {
        Button {
            activeSheet = .contactList
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                Text("search.prompt")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var accessDeniedOverlay: some View {
        if model.access == .denied {
            ContentUnavailableView {
                Label("permission.contacts.title", systemImage: "person.crop.circle.badge.exclamationmark")
            } description: {
                Text("permission.contacts.message")
            } actions: {
                Button("permission.open_settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .background(.regularMaterial)
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: MapSheet) -> some View {
        switch sheet {
        case .contactList:
            ContactListSheetView(
                onSelect: { contact in focus(on: contact) },
                onClose: closeSelection
            )
        case .place(let place):
            PlaceSheetView(place: place)
        case .contact(let contact):
            ContactDetailView(contact: contact)
        case .location(let pin):
            LocationSheetView(pin: pin)
        }
    }

    // MARK: - Actions

    private func closeSelection() {
        activeSheet = nil
        droppedPin = nil
    }

    /// 一覧から選んだ連絡先へ地図を移動し、概要シートを開く
    /// (Android版 showMarkerInfoWindow(animate:) 相当)。
    private func focus(on contact: Contact) {
        if let coordinate = contact.coordinate {
            withAnimation {
                position = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
        if isWidePresentation {
            // カード内の切り替えなので即座に表示できる
            activeSheet = .contact(contact)
        } else {
            activeSheet = nil
            Task {
                // 前のシートが閉じ切るのを待ってから次を出す
                try? await Task.sleep(for: .milliseconds(500))
                activeSheet = .contact(contact)
            }
        }
    }

    /// 長押しでピンを置き、逆ジオコーディング用のシートを開く。
    private func dropPinGesture(proxy: MapProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.4)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onEnded { value in
                guard
                    case .second(true, let drag?) = value,
                    let coordinate = proxy.convert(drag.location, from: .local)
                else { return }
                let pin = DroppedPin(coordinate: coordinate)
                droppedPin = pin
                activeSheet = .location(pin)
            }
    }
}
