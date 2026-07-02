import SwiftUI

/// グループ絞り込み+再読み込みのメニュー。
/// ラベルの見た目は呼び出し側が決める。
struct GroupMenuView<LabelContent: View>: View {
    @Environment(ContactsModel.self) private var model
    @ViewBuilder let label: (String) -> LabelContent

    var body: some View {
        @Bindable var model = model
        return Menu {
            Picker("", selection: $model.selectedGroupID) {
                ForEach(model.groups) { group in
                    Text(group.name).tag(group.id)
                }
            }
            .pickerStyle(.inline)
            Divider()
            Button {
                Task { await model.reload() }
            } label: {
                Label("action.reload", systemImage: "arrow.clockwise")
            }
        } label: {
            label(currentGroupName)
        }
    }

    private var currentGroupName: String {
        model.groups.first(where: { $0.id == model.selectedGroupID })?.name
            ?? ContactGroup.allContacts.name
    }
}
