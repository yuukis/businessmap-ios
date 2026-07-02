import SwiftUI

/// 検索付きの連絡先一覧シート(Android版の一覧パネル+SearchBar 相当)。
struct ContactListSheetView: View {
    @Environment(ContactsModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    let onSelect: (Contact) -> Void

    var body: some View {
        NavigationStack {
            list
                .navigationTitle("list.title")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: $query,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text("search.prompt")
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("common.close") { dismiss() }
                    }
                }
        }
    }

    @ViewBuilder
    private var list: some View {
        let filtered = ContactSearchFilter.filter(model.visibleContacts, query: query)
        if filtered.isEmpty {
            if query.isEmpty {
                ContentUnavailableView(
                    "list.empty",
                    systemImage: "person.2.slash",
                    description: Text("list.empty.description")
                )
            } else {
                ContentUnavailableView.search(text: query)
            }
        } else {
            List(filtered) { contact in
                Button {
                    onSelect(contact)
                } label: {
                    ContactRowView(contact: contact)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }
}
