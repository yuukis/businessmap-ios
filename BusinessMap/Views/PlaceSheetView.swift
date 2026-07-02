import SwiftUI

/// ピン選択時のシート。1件ならそのまま概要を、
/// 同一座標に複数の連絡先があれば一覧から選ばせる
/// (Android版の「他 N 件」ダイアログ相当)。
struct PlaceSheetView: View {
    let place: MapPlace

    var body: some View {
        if place.contacts.count == 1 {
            ContactDetailView(contact: place.contacts[0])
        } else {
            NavigationStack {
                List(place.contacts) { contact in
                    NavigationLink(value: contact) {
                        ContactRowView(contact: contact)
                    }
                }
                .listStyle(.plain)
                .navigationTitle(Text(String(
                    format: String(localized: "place.contacts_count"),
                    place.contacts.count
                )))
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Contact.self) { contact in
                    ContactDetailView(contact: contact)
                }
            }
        }
    }
}
