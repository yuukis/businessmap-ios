import SwiftUI

/// レギュラー幅 (iPad や大型 iPhone の横向き) で地図の左に重ねる
/// フローティングパネル。コンパクト幅のシート群 (検索一覧・連絡先概要・
/// 複数件選択・長押し地点) をこのパネル1枚に置き換える
/// (Android版タブレットのサイドドロワー相当)。
struct SidePanelView<SelectionContent: View>: View {
    /// 現在の選択内容。nil / .contactList は一覧を表示する
    let selection: MapSheet?
    let onClose: () -> Void
    let onSelectContact: (Contact) -> Void
    @ViewBuilder let selectionContent: (MapSheet) -> SelectionContent

    @State private var query = ""

    var body: some View {
        Group {
            if let selection, isDetail(selection) {
                selectionContent(selection)
                    .overlay(alignment: .topTrailing) { closeButton }
            } else {
                listPanel
            }
        }
        .scrollContentBackground(.hidden)
        .frame(width: 360)
        .frame(maxHeight: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .padding(12)
    }

    private func isDetail(_ sheet: MapSheet) -> Bool {
        switch sheet {
        case .contactList: false
        case .place, .contact, .location: true
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    private var listPanel: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                GroupMenuView { name in
                    HStack {
                        Label(name, systemImage: "person.2")
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                }
                .foregroundStyle(.primary)
                searchField
            }
            .padding(12)
            Divider()
            ContactListBody(query: query, onSelect: onSelectContact)
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("search.prompt", text: $query)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 10))
    }
}
