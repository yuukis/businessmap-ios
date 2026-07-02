import Contacts
import Foundation

/// Contacts framework から連絡先・グループを読み取る。
/// CNContactStore はスレッドセーフなので、重いフェッチはバックグラウンドから呼んでよい。
final class ContactRepository: @unchecked Sendable {
    private let store = CNContactStore()

    /// 連絡先へのアクセスを(必要なら要求したうえで)確認する。
    func requestAccess() async -> Bool {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            return true
        case .notDetermined:
            return (try? await store.requestAccess(for: .contacts)) ?? false
        default:
            // .denied / .restricted。iOS 18 の .limited もここに落ちるが、
            // その場合も enumerateContacts は許可された範囲で動作するため
            // 将来的には許可扱いにする余地がある。
            return false
        }
    }

    /// すべての連絡先を読み取り、住所ごとに `Contact` へ展開して返す。
    /// 並び順は連絡先アプリのユーザー設定に従う。
    func fetchContacts() throws -> [Contact] {
        let keys: [CNKeyDescriptor] = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactFormatter.descriptorForRequiredKeys(for: .phoneticFullName),
            CNContactPostalAddressesKey as CNKeyDescriptor,
            CNContactOrganizationNameKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor,
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .userDefault
        request.unifyResults = true

        let nameFormatter = CNContactFormatter()
        nameFormatter.style = .fullName
        let phoneticFormatter = CNContactFormatter()
        phoneticFormatter.style = .phoneticFullName
        let postalFormatter = CNPostalAddressFormatter()

        var contacts: [Contact] = []
        try store.enumerateContacts(with: request) { cnContact, _ in
            let name = nameFormatter.string(from: cnContact)
                ?? String(localized: "contact.no_name")
            let phonetic = phoneticFormatter.string(from: cnContact)
            let organization = cnContact.organizationName.isEmpty
                ? nil : cnContact.organizationName

            if cnContact.postalAddresses.isEmpty {
                contacts.append(
                    Contact(
                        id: cnContact.identifier,
                        contactId: cnContact.identifier,
                        displayName: name,
                        phoneticName: phonetic,
                        organizationName: organization,
                        thumbnailData: cnContact.thumbnailImageData
                    )
                )
            } else {
                for (index, labeledAddress) in cnContact.postalAddresses.enumerated() {
                    let address = postalFormatter
                        .string(from: labeledAddress.value)
                        .replacingOccurrences(of: "\n", with: " ")
                    contacts.append(
                        Contact(
                            id: "\(cnContact.identifier)#\(index)",
                            contactId: cnContact.identifier,
                            displayName: name,
                            phoneticName: phonetic,
                            organizationName: organization,
                            postalAddress: address,
                            thumbnailData: cnContact.thumbnailImageData
                        )
                    )
                }
            }
        }
        return contacts
    }

    /// デバイス上の連絡先グループ一覧を返す(「すべての連絡先」は含まない)。
    func fetchGroups() throws -> [ContactGroup] {
        try store.groups(matching: nil).map { group in
            ContactGroup(id: .group(group.identifier), name: group.name)
        }
    }

    /// 指定グループに属する連絡先の identifier 集合を返す。
    func fetchMemberIdentifiers(groupIdentifier: String) throws -> Set<String> {
        let predicate = CNContact.predicateForContactsInGroup(withIdentifier: groupIdentifier)
        let members = try store.unifiedContacts(
            matching: predicate,
            keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor]
        )
        return Set(members.map(\.identifier))
    }
}
