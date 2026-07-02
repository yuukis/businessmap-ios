import SwiftUI

/// 検索付きの連絡先一覧(Android版の一覧パネル+SearchBar 相当)。
/// コンパクト幅ではシートとして、レギュラー幅ではフローティングカード内で使う。
struct ContactListSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    let onSelect: (Contact) -> Void
    /// カード内など、シートの dismiss が効かない場所で閉じるための差し替え
    var onClose: (() -> Void)?

    var body: some View {
        NavigationStack {
            ContactListBody(query: query, onSelect: onSelect)
                .navigationTitle("list.title")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: $query,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text("search.prompt")
                )
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("common.close") {
                            if let onClose {
                                onClose()
                            } else {
                                dismiss()
                            }
                        }
                    }
                }
        }
    }
}

/// 検索クエリで絞り込んだ連絡先一覧。
struct ContactListBody: View {
    @Environment(ContactsModel.self) private var model

    let query: String
    let onSelect: (Contact) -> Void

    var body: some View {
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
