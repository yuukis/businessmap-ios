import Contacts
import SwiftUI

/// 長押し地点のシート。逆ジオコーディングした住所を表示し、
/// 連絡先登録・経路案内につなげる(Android版 LocationActionFragment 相当)。
struct LocationSheetView: View {
    let pin: DroppedPin

    @Environment(ContactsModel.self) private var model

    private enum AddressState {
        case loading
        case loaded(GeocodingService.ReverseGeocodedAddress)
        case failed
    }

    @State private var addressState: AddressState = .loading
    @State private var showsNewContact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("location.title")
                .font(.title3.bold())
            addressView
            actionButtons
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .task {
            if let result = await model.reverseGeocodedAddress(for: pin.coordinate) {
                addressState = .loaded(result)
            } else {
                addressState = .failed
            }
        }
        .sheet(isPresented: $showsNewContact) {
            ContactCardView(mode: .newContact(postalAddress: loadedPostalAddress))
                .ignoresSafeArea()
        }
    }

    private var loadedPostalAddress: CNPostalAddress? {
        if case .loaded(let result) = addressState {
            return result.postalAddress
        }
        return nil
    }

    @ViewBuilder
    private var addressView: some View {
        switch addressState {
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                Text("location.loading")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        case .loaded(let result):
            Label(result.formatted, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
        case .failed:
            Text("location.failed")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                ExternalNavigation.openDirections(to: pin.coordinate, name: nil)
            } label: {
                Label("action.directions", systemImage: "car.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                showsNewContact = true
            } label: {
                Label("action.register_contact", systemImage: "person.crop.circle.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .controlSize(.large)
    }
}
