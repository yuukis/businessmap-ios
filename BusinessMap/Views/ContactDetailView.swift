import SwiftUI

/// 連絡先の概要と主要アクション(Android版 InfoWindow + ContactsActionFragment 相当)。
struct ContactDetailView: View {
    let contact: Contact
    @State private var showsContactCard = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if let address = contact.postalAddress {
                    Label(address, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                actionButtons
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .sheet(isPresented: $showsContactCard) {
            ContactCardView(mode: .existing(contactId: contact.contactId))
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            ContactAvatarView(contact: contact, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                if let phonetic = contact.phoneticName, !phonetic.isEmpty {
                    Text(phonetic)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(contact.displayName)
                    .font(.title3.bold())
                if let organization = contact.organizationName {
                    Text(organization)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                if let coordinate = contact.coordinate {
                    ExternalNavigation.openDirections(to: coordinate, name: contact.displayName)
                }
            } label: {
                Label("action.directions", systemImage: "car.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(contact.coordinate == nil)

            Button {
                showsContactCard = true
            } label: {
                Label("action.show_contact", systemImage: "person.crop.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .controlSize(.large)
    }
}
