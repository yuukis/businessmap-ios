import Foundation

/// 連絡先グループ。iOS では CNGroup が Android のグループに相当する。
/// 「すべての連絡先」は実グループではないため専用の ID を持つ。
struct ContactGroup: Identifiable, Hashable, Sendable {
    enum GroupID: Hashable, Sendable {
        case all
        case group(String) // CNGroup.identifier
    }

    let id: GroupID
    let name: String

    static let allContacts = ContactGroup(
        id: .all,
        name: String(localized: "group.all_contacts")
    )
}
